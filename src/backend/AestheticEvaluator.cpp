#include "AestheticEvaluator.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcessEnvironment>

namespace {

struct AestheticRuntimePaths {
    QString projectRoot;
    QString scriptPath;
    QString pythonExe;
    QString eatRoot;
    QString finetuneWeight;
    QString pretrainWeight;
    QString device = QStringLiteral("cpu");

    bool isComplete() const
    {
        return !scriptPath.isEmpty() && !pythonExe.isEmpty()
               && !eatRoot.isEmpty() && !finetuneWeight.isEmpty();
    }
};

QString findExistingFile(const QDir &dir, const QStringList &names)
{
    for (const QString &name : names) {
        const QString path = dir.absoluteFilePath(name);
        if (QFile::exists(path))
            return path;
    }
    return QString();
}

AestheticRuntimePaths resolveRuntimePaths()
{
    AestheticRuntimePaths paths;
    QDir dir(QCoreApplication::applicationDirPath());

    for (int i = 0; i < 7; ++i) {
        const QString aestheticsDir = dir.absoluteFilePath(QStringLiteral("aesthetics"));
        const QString scriptInAesthetics = aestheticsDir + QStringLiteral("/eat_server.py");
        const QString scriptInScripts = dir.absoluteFilePath(QStringLiteral("scripts/aesthetics/eat_server.py"));

        if (QFile::exists(scriptInAesthetics))
            paths.scriptPath = scriptInAesthetics;
        else if (QFile::exists(scriptInScripts))
            paths.scriptPath = scriptInScripts;

        if (!paths.scriptPath.isEmpty()) {
            paths.projectRoot = dir.absolutePath();

            const QString venvPython = aestheticsDir + QStringLiteral("/venv/Scripts/python.exe");
            if (QFile::exists(venvPython))
                paths.pythonExe = venvPython;
            else if (!qEnvironmentVariableIsEmpty("IMAGEBROWSER_PYTHON"))
                paths.pythonExe = qEnvironmentVariable("IMAGEBROWSER_PYTHON");
            else
                paths.pythonExe = QStringLiteral("python");

            if (!qEnvironmentVariableIsEmpty("IMAGEBROWSER_EAT_ROOT"))
                paths.eatRoot = qEnvironmentVariable("IMAGEBROWSER_EAT_ROOT");
            else if (QDir(aestheticsDir + QStringLiteral("/eat-repo/AVA")).exists())
                paths.eatRoot = aestheticsDir + QStringLiteral("/eat-repo/AVA");
            else if (QDir(aestheticsDir + QStringLiteral("/AVA")).exists())
                paths.eatRoot = aestheticsDir + QStringLiteral("/AVA");

            if (!qEnvironmentVariableIsEmpty("IMAGEBROWSER_EAT_WEIGHT"))
                paths.finetuneWeight = qEnvironmentVariable("IMAGEBROWSER_EAT_WEIGHT");
            else {
                const QDir weightsDir(aestheticsDir + QStringLiteral("/weights"));
                paths.finetuneWeight = findExistingFile(weightsDir,
                    {QStringLiteral("finetune.pth"),
                     QStringLiteral("model.pth"),
                     QStringLiteral("eat.pth")});
                if (paths.finetuneWeight.isEmpty() && weightsDir.exists()) {
                    const QStringList pthFiles = weightsDir.entryList({QStringLiteral("*.pth")}, QDir::Files);
                    for (const QString &fileName : pthFiles) {
                        if (fileName != QStringLiteral("pretrain.pth")) {
                            paths.finetuneWeight = weightsDir.absoluteFilePath(fileName);
                            break;
                        }
                    }
                }
            }

            if (!qEnvironmentVariableIsEmpty("IMAGEBROWSER_EAT_PRETRAIN"))
                paths.pretrainWeight = qEnvironmentVariable("IMAGEBROWSER_EAT_PRETRAIN");
            else
                paths.pretrainWeight = aestheticsDir + QStringLiteral("/weights/pretrain.pth");

            if (!qEnvironmentVariableIsEmpty("IMAGEBROWSER_EAT_DEVICE"))
                paths.device = qEnvironmentVariable("IMAGEBROWSER_EAT_DEVICE");

            return paths;
        }

        if (!dir.cdUp())
            break;
    }

    return paths;
}

} // namespace

AestheticEvaluator::AestheticEvaluator(QObject *parent)
    : QObject(parent)
{
}

AestheticEvaluator::~AestheticEvaluator()
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

void AestheticEvaluator::setMockScorer(const std::function<double(const QString &)> &scorer)
{
    m_mockScorer = scorer;
    setAvailable(scorer != nullptr);
}

bool AestheticEvaluator::hasCachedScore(const QString &imagePath) const
{
    return m_cache.contains(imagePath);
}

double AestheticEvaluator::cachedScore(const QString &imagePath) const
{
    return m_cache.value(imagePath, 0.0);
}

QString AestheticEvaluator::statusHint() const
{
    return m_statusHint;
}

void AestheticEvaluator::requestScore(const QString &imagePath)
{
    if (imagePath.isEmpty())
        return;

    if (m_cache.contains(imagePath)) {
        emit scoreReady(imagePath, m_cache.value(imagePath));
        return;
    }

    if (m_mockScorer) {
        const double score = m_mockScorer(imagePath);
        m_cache.insert(imagePath, score);
        emit scoreReady(imagePath, score);
        return;
    }

    m_pendingPath = imagePath;

    if (!m_process && !m_serverStarting)
        startServer();

    if (!m_available) {
        if (m_serverStarting)
            setBusy(true);
        else
            emit scoreFailed(imagePath, m_statusHint.isEmpty()
                                         ? QStringLiteral("aesthetic server unavailable")
                                         : m_statusHint);
        return;
    }

    if (m_busy)
        return;

    sendRequest(imagePath);
}

void AestheticEvaluator::startServer()
{
    if (m_process || m_serverStarting)
        return;

    const AestheticRuntimePaths paths = resolveRuntimePaths();
    if (!paths.isComplete()) {
        if (paths.scriptPath.isEmpty()) {
            m_statusHint = QString::fromUtf8(u8"未找到 aesthetics 目录");
        } else if (paths.eatRoot.isEmpty()) {
            m_statusHint = QString::fromUtf8(u8"请运行 scripts\\setup_aesthetics.bat");
        } else if (paths.finetuneWeight.isEmpty()) {
            m_statusHint = QString::fromUtf8(u8"请将 finetune.pth 放入 aesthetics\\weights\\");
        } else {
            m_statusHint = QString::fromUtf8(u8"美学模型未就绪");
        }
        setAvailable(false);
        return;
    }

    m_serverStarting = true;
    m_process = new QProcess(this);
    m_process->setProcessChannelMode(QProcess::MergedChannels);

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("IMAGEBROWSER_EAT_ROOT"), QDir::toNativeSeparators(paths.eatRoot));
    env.insert(QStringLiteral("IMAGEBROWSER_EAT_WEIGHT"), QDir::toNativeSeparators(paths.finetuneWeight));
    if (QFile::exists(paths.pretrainWeight))
        env.insert(QStringLiteral("IMAGEBROWSER_EAT_PRETRAIN"), QDir::toNativeSeparators(paths.pretrainWeight));
    env.insert(QStringLiteral("IMAGEBROWSER_EAT_DEVICE"), paths.device);
    env.insert(QStringLiteral("PYTHONUNBUFFERED"), QStringLiteral("1"));
    env.insert(QStringLiteral("PYTHONIOENCODING"), QStringLiteral("utf-8"));
    m_process->setProcessEnvironment(env);

    connect(m_process, &QProcess::readyReadStandardOutput, this, &AestheticEvaluator::onProcessReadyRead);
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &AestheticEvaluator::onProcessFinished);
    connect(m_process, &QProcess::errorOccurred, this, &AestheticEvaluator::onProcessError);

    m_process->start(paths.pythonExe, {paths.scriptPath});
}

void AestheticEvaluator::sendRequest(const QString &imagePath)
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

void AestheticEvaluator::onProcessReadyRead()
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

void AestheticEvaluator::handleLine(const QString &line)
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
                emit scoreFailed(m_pendingPath, m_statusHint);
        }
        return;
    }

    setBusy(false);

    const QString path = obj.value(QStringLiteral("path")).toString();
    const bool ok = obj.value(QStringLiteral("ok")).toBool(false);
    if (ok) {
        const double score = obj.value(QStringLiteral("score")).toDouble(0.0);
        const QString normalizedPath = QDir::fromNativeSeparators(path);
        m_cache.insert(normalizedPath, score);
        emit scoreReady(normalizedPath, score);
    } else {
        const QString error = obj.value(QStringLiteral("error")).toString();
        const QString normalizedPath = path.isEmpty() ? m_pendingPath : QDir::fromNativeSeparators(path);
        emit scoreFailed(normalizedPath, error);
    }

    const QString pending = QDir::fromNativeSeparators(m_pendingPath);
    const QString completed = QDir::fromNativeSeparators(path);
    if (!pending.isEmpty() && pending != completed && !m_cache.contains(pending))
        sendRequest(m_pendingPath);
}

void AestheticEvaluator::onProcessFinished(int exitCode, QProcess::ExitStatus status)
{
    Q_UNUSED(exitCode)
    Q_UNUSED(status)
    m_serverStarting = false;
    setBusy(false);
    setAvailable(false);
    m_process->deleteLater();
    m_process = nullptr;
}

void AestheticEvaluator::onProcessError(QProcess::ProcessError error)
{
    if (error == QProcess::FailedToStart) {
        m_serverStarting = false;
        m_statusHint = QString::fromUtf8(u8"无法启动 Python，请先运行 scripts\\setup_aesthetics.bat");
        setAvailable(false);
    }
}

void AestheticEvaluator::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged(m_busy);
}

void AestheticEvaluator::setAvailable(bool available)
{
    if (m_available == available)
        return;
    m_available = available;
    emit availabilityChanged(m_available);
}

QString AestheticEvaluator::findServerScript() const
{
    return resolveRuntimePaths().scriptPath;
}
