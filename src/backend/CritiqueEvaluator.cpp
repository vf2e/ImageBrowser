#include "CritiqueEvaluator.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcessEnvironment>

namespace {

struct CritiqueRuntimePaths {
    QString scriptPath;
    QString pythonExe;
    QString modelId = QStringLiteral("zhangzicheng/q-sit-mini");
    QString device = QStringLiteral("cuda");

    bool isComplete() const
    {
        return !scriptPath.isEmpty() && !pythonExe.isEmpty();
    }
};

CritiqueRuntimePaths resolveRuntimePaths()
{
    CritiqueRuntimePaths paths;
    QDir dir(QCoreApplication::applicationDirPath());

    for (int i = 0; i < 7; ++i) {
        const QString aestheticsDir = dir.absoluteFilePath(QStringLiteral("aesthetics"));
        const QString scriptInAesthetics = aestheticsDir + QStringLiteral("/qsit_server.py");

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

            if (!qEnvironmentVariableIsEmpty("IMAGEBROWSER_QSIT_MODEL"))
                paths.modelId = qEnvironmentVariable("IMAGEBROWSER_QSIT_MODEL");
            if (!qEnvironmentVariableIsEmpty("IMAGEBROWSER_QSIT_DEVICE"))
                paths.device = qEnvironmentVariable("IMAGEBROWSER_QSIT_DEVICE");

            return paths;
        }

        if (!dir.cdUp())
            break;
    }

    return paths;
}

} // namespace

CritiqueEvaluator::CritiqueEvaluator(QObject *parent)
    : QObject(parent)
{
}

CritiqueEvaluator::~CritiqueEvaluator()
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

void CritiqueEvaluator::setMockGenerator(const std::function<QString(const QString &)> &generator)
{
    m_mockGenerator = generator;
    setAvailable(generator != nullptr);
}

bool CritiqueEvaluator::hasCachedCritique(const QString &imagePath) const
{
    const QString key = QDir::fromNativeSeparators(imagePath);
    return m_cache.contains(key);
}

QString CritiqueEvaluator::cachedCritique(const QString &imagePath) const
{
    return m_cache.value(QDir::fromNativeSeparators(imagePath));
}

double CritiqueEvaluator::cachedCritiqueScore(const QString &imagePath) const
{
    return m_scoreCache.value(QDir::fromNativeSeparators(imagePath), -1.0);
}

QString CritiqueEvaluator::statusHint() const
{
    return m_statusHint;
}

void CritiqueEvaluator::requestCritique(const QString &imagePath)
{
    if (imagePath.isEmpty())
        return;

    const QString normalizedPath = QDir::fromNativeSeparators(imagePath);
    if (m_cache.contains(normalizedPath)) {
        emit critiqueReady(normalizedPath, m_cache.value(normalizedPath),
                           m_scoreCache.value(normalizedPath, -1.0));
        return;
    }

    if (m_mockGenerator) {
        const QString text = m_mockGenerator(imagePath);
        m_cache.insert(normalizedPath, text);
        m_scoreCache.insert(normalizedPath, 7.35);
        emit critiqueReady(normalizedPath, text, 7.35);
        return;
    }

    m_pendingPath = imagePath;

    if (!m_process && !m_serverStarting)
        startServer();

    if (!m_available) {
        if (m_serverStarting)
            setBusy(true);
        else
            emit critiqueFailed(imagePath, m_statusHint.isEmpty()
                                              ? QStringLiteral("critique server unavailable")
                                              : m_statusHint);
        return;
    }

    if (m_busy)
        return;

    sendRequest(imagePath);
}

void CritiqueEvaluator::startServer()
{
    if (m_process || m_serverStarting)
        return;

    const CritiqueRuntimePaths paths = resolveRuntimePaths();
    if (!paths.isComplete()) {
        m_statusHint = QString::fromUtf8(u8"未找到 qsit_server.py，请先运行 scripts\\setup_aesthetics.bat");
        setAvailable(false);
        return;
    }

    m_serverStarting = true;
    m_statusHint = QString::fromUtf8(u8"正在加载 Q-SiT 模型...");
    m_process = new QProcess(this);
    m_process->setProcessChannelMode(QProcess::MergedChannels);

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("IMAGEBROWSER_QSIT_MODEL"), paths.modelId);
    env.insert(QStringLiteral("IMAGEBROWSER_QSIT_DEVICE"), paths.device);
    env.insert(QStringLiteral("PYTHONUNBUFFERED"), QStringLiteral("1"));
    env.insert(QStringLiteral("PYTHONIOENCODING"), QStringLiteral("utf-8"));
    env.insert(QStringLiteral("HF_HOME"),
               QDir::toNativeSeparators(QFileInfo(paths.scriptPath).absolutePath()
                                        + QStringLiteral("/hf_cache")));
    m_process->setProcessEnvironment(env);

    connect(m_process, &QProcess::readyReadStandardOutput, this, &CritiqueEvaluator::onProcessReadyRead);
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &CritiqueEvaluator::onProcessFinished);
    connect(m_process, &QProcess::errorOccurred, this, &CritiqueEvaluator::onProcessError);

    m_process->start(paths.pythonExe, {paths.scriptPath});
}

void CritiqueEvaluator::sendRequest(const QString &imagePath)
{
    if (!m_process || m_process->state() != QProcess::Running)
        return;

    setBusy(true);
    m_pendingPath = imagePath;

    QJsonObject req;
    req.insert(QStringLiteral("path"), QDir::fromNativeSeparators(imagePath));
    const QByteArray payload = QJsonDocument(req).toJson(QJsonDocument::Compact) + '\n';
    m_process->write(payload);
    m_process->waitForBytesWritten(3000);
}

void CritiqueEvaluator::onProcessReadyRead()
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

void CritiqueEvaluator::handleLine(const QString &line)
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
            setAvailable(true);
            if (!m_pendingPath.isEmpty())
                sendRequest(m_pendingPath);
        } else {
            m_statusHint = obj.value(QStringLiteral("error")).toString();
            setAvailable(false);
            setBusy(false);
            if (!m_statusHint.isEmpty())
                emit critiqueFailed(m_pendingPath, m_statusHint);
        }
        return;
    }

    setBusy(false);

    const QString path = obj.value(QStringLiteral("path")).toString();
    const bool ok = obj.value(QStringLiteral("ok")).toBool(false);
    if (ok) {
        const QString text = obj.value(QStringLiteral("text")).toString();
        const double score = obj.value(QStringLiteral("score")).toDouble(-1.0);
        const QString normalizedPath = QDir::fromNativeSeparators(path);
        m_cache.insert(normalizedPath, text);
        if (score >= 0.0)
            m_scoreCache.insert(normalizedPath, score);
        emit critiqueReady(normalizedPath, text, score);
    } else {
        const QString error = obj.value(QStringLiteral("error")).toString();
        const QString normalizedPath = path.isEmpty() ? m_pendingPath : QDir::fromNativeSeparators(path);
        emit critiqueFailed(normalizedPath, error);
    }

    const QString pending = QDir::fromNativeSeparators(m_pendingPath);
    const QString completed = QDir::fromNativeSeparators(path);
    if (!pending.isEmpty() && pending != completed && !m_cache.contains(pending))
        sendRequest(m_pendingPath);
}

void CritiqueEvaluator::onProcessFinished(int exitCode, QProcess::ExitStatus status)
{
    Q_UNUSED(exitCode)
    Q_UNUSED(status)
    m_serverStarting = false;
    setBusy(false);
    setAvailable(false);
    m_process->deleteLater();
    m_process = nullptr;
}

void CritiqueEvaluator::onProcessError(QProcess::ProcessError error)
{
    if (error == QProcess::FailedToStart) {
        m_serverStarting = false;
        m_statusHint = QString::fromUtf8(u8"无法启动 Python，请先运行 scripts\\setup_aesthetics.bat");
        setAvailable(false);
    }
}

void CritiqueEvaluator::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged(m_busy);
}

void CritiqueEvaluator::setAvailable(bool available)
{
    if (m_available == available)
        return;
    m_available = available;
    emit availabilityChanged(m_available);
}
