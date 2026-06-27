#include "AssistantEvaluator.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcessEnvironment>

namespace {

struct AssistantRuntimePaths {
    QString scriptPath;
    QString pythonExe;

    bool isComplete() const
    {
        return !scriptPath.isEmpty() && !pythonExe.isEmpty();
    }
};

AssistantRuntimePaths resolveRuntimePaths()
{
    AssistantRuntimePaths paths;
    QDir dir(QCoreApplication::applicationDirPath());

    for (int i = 0; i < 7; ++i) {
        const QString aestheticsDir = dir.absoluteFilePath(QStringLiteral("aesthetics"));
        const QString scriptInAesthetics = aestheticsDir + QStringLiteral("/assistant_server.py");

        if (QFile::exists(scriptInAesthetics))
            paths.scriptPath = scriptInAesthetics;

        if (!paths.scriptPath.isEmpty()) {
            const QString venvPython = aestheticsDir + QStringLiteral("/venv/Scripts/python.exe");
            if (QFile::exists(venvPython))
                paths.pythonExe = venvPython;
            else if (!qEnvironmentVariableIsEmpty("IMAGEBROWSER_PYTHON"))
                paths.pythonExe = qEnvironmentVariable("IMAGEBROWSER_PYTHON");
            else
                paths.pythonExe = QStringLiteral("python");

            return paths;
        }

        if (!dir.cdUp())
            break;
    }

    return paths;
}

QJsonArray historyToJson(const QVariantList &history)
{
    QJsonArray arr;
    for (const QVariant &item : history) {
        const QVariantMap map = item.toMap();
        const QString role = map.value(QStringLiteral("role")).toString();
        const QString text = map.value(QStringLiteral("text")).toString();
        if (role.isEmpty() || text.isEmpty())
            continue;
        QJsonObject entry;
        entry.insert(QStringLiteral("role"), role);
        entry.insert(QStringLiteral("content"), text);
        arr.append(entry);
    }
    return arr;
}

} // namespace

AssistantEvaluator::AssistantEvaluator(QObject *parent)
    : QObject(parent)
{
}

AssistantEvaluator::~AssistantEvaluator()
{
    if (m_process) {
        m_process->disconnect(this);
        m_process->terminate();
        if (!m_process->waitForFinished(2000))
            m_process->kill();
        delete m_process;
        m_process = nullptr;
    }
}

void AssistantEvaluator::setMockResponder(
    const std::function<QString(const QString &, const QVariantList &)> &responder)
{
    m_mockResponder = responder;
    setAvailable(responder != nullptr);
}

QString AssistantEvaluator::statusHint() const
{
    return m_statusHint;
}

void AssistantEvaluator::sendMessage(const QString &message, const QVariantList &history)
{
    if (message.trimmed().isEmpty())
        return;

    if (m_mockResponder) {
        const QString reply = m_mockResponder(message, history);
        emit replyReady(reply);
        return;
    }

    m_pendingMessage = message;
    m_pendingHistory = history;

    if (!m_process && !m_serverStarting)
        startServer();

    if (!m_available) {
        if (m_serverStarting)
            setBusy(true);
        else
            emit replyFailed(m_statusHint.isEmpty()
                                 ? QStringLiteral("assistant server unavailable")
                                 : m_statusHint);
        return;
    }

    if (m_busy)
        return;

    sendRequest(message, history);
}

void AssistantEvaluator::startServer()
{
    if (m_process || m_serverStarting)
        return;

    const AssistantRuntimePaths paths = resolveRuntimePaths();
    if (!paths.isComplete()) {
        m_statusHint = QString::fromUtf8(u8"未找到 assistant_server.py，请先运行 scripts\\setup_aesthetics.bat");
        setAvailable(false);
        return;
    }

    m_serverStarting = true;
    m_statusHint = QString::fromUtf8(u8"正在启动小助理…");
    m_process = new QProcess(this);
    m_process->setProcessChannelMode(QProcess::MergedChannels);

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("PYTHONUNBUFFERED"), QStringLiteral("1"));
    env.insert(QStringLiteral("PYTHONIOENCODING"), QStringLiteral("utf-8"));
    env.insert(QStringLiteral("HF_HOME"),
               QDir::toNativeSeparators(QFileInfo(paths.scriptPath).absolutePath()
                                        + QStringLiteral("/hf_cache")));
    m_process->setProcessEnvironment(env);

    connect(m_process, &QProcess::readyReadStandardOutput, this, &AssistantEvaluator::onProcessReadyRead);
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &AssistantEvaluator::onProcessFinished);
    connect(m_process, &QProcess::errorOccurred, this, &AssistantEvaluator::onProcessError);

    m_process->start(paths.pythonExe, {paths.scriptPath});
}

void AssistantEvaluator::sendRequest(const QString &message, const QVariantList &history)
{
    if (!m_process || m_process->state() != QProcess::Running)
        return;

    setBusy(true);
    m_pendingMessage = message;
    m_pendingHistory = history;

    QJsonObject req;
    req.insert(QStringLiteral("message"), message);
    req.insert(QStringLiteral("history"), historyToJson(history));
    const QByteArray payload = QJsonDocument(req).toJson(QJsonDocument::Compact) + '\n';
    m_process->write(payload);
    m_process->waitForBytesWritten(3000);
}

void AssistantEvaluator::onProcessReadyRead()
{
    if (!m_process)
        return;

    m_readBuffer.append(m_process->readAllStandardOutput());
    while (true) {
        const int lineEnd = m_readBuffer.indexOf('\n');
        if (lineEnd < 0)
            break;
        const QByteArray lineBytes = m_readBuffer.left(lineEnd);
        m_readBuffer.remove(0, lineEnd + 1);
        handleLine(QString::fromUtf8(lineBytes));
    }
}

void AssistantEvaluator::handleLine(const QString &line)
{
    if (line.trimmed().isEmpty())
        return;

    const QJsonDocument doc = QJsonDocument::fromJson(line.toUtf8());
    if (!doc.isObject())
        return;

    const QJsonObject obj = doc.object();

    if (obj.contains(QStringLiteral("ready"))) {
        m_serverStarting = false;
        const bool ready = obj.value(QStringLiteral("ready")).toBool(false);
        if (ready) {
            m_statusHint.clear();
            const QString welcome = obj.value(QStringLiteral("welcome")).toString();
            if (!welcome.isEmpty() && m_welcomeMessage != welcome) {
                m_welcomeMessage = welcome;
                emit welcomeMessageChanged();
            }
            setAvailable(true);
            if (!m_pendingMessage.isEmpty())
                sendRequest(m_pendingMessage, m_pendingHistory);
        } else {
            m_statusHint = obj.value(QStringLiteral("error")).toString();
            setAvailable(false);
            setBusy(false);
            if (!m_statusHint.isEmpty())
                emit replyFailed(m_statusHint);
        }
        return;
    }

    setBusy(false);

    const bool ok = obj.value(QStringLiteral("ok")).toBool(false);
    if (ok) {
        emit replyReady(obj.value(QStringLiteral("reply")).toString());
    } else {
        emit replyFailed(obj.value(QStringLiteral("error")).toString());
    }
}

void AssistantEvaluator::onProcessFinished(int exitCode, QProcess::ExitStatus status)
{
    Q_UNUSED(exitCode)
    Q_UNUSED(status)
    m_serverStarting = false;
    setBusy(false);
    setAvailable(false);
    m_process->deleteLater();
    m_process = nullptr;
}

void AssistantEvaluator::onProcessError(QProcess::ProcessError error)
{
    if (error == QProcess::FailedToStart) {
        m_serverStarting = false;
        m_statusHint = QString::fromUtf8(u8"无法启动 Python，请先运行 scripts\\setup_aesthetics.bat");
        setAvailable(false);
    }
}

void AssistantEvaluator::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged(m_busy);
}

void AssistantEvaluator::setAvailable(bool available)
{
    if (m_available == available)
        return;
    m_available = available;
    emit availabilityChanged(m_available);
}
