#include "ImageBrowserBackend.h"
#include "AestheticEvaluator.h"
#include "CritiqueEvaluator.h"
#include "AssistantEvaluator.h"

#include <QFileInfo>
#include <QFileDialog>
#include <QDir>
#include <QStandardPaths>
#include <QFileInfo>
#include <QDebug>
#include <QtConcurrent>
#include <QSettings>
#include <QTextStream>
#include <QVariantMap>

static const QStringList IMAGE_SUFFIXES = {"*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.webp"};

// u8 字面量保证中文文案为 UTF-8，避免 MSVC 源文件编码与 tr() 混用导致乱码
static QString u8msg(const char *text)
{
    return QString::fromUtf8(text);
}

static bool sameImagePath(const QString &left, const QString &right)
{
    if (left.isEmpty() || right.isEmpty())
        return left == right;
    return QDir::fromNativeSeparators(left).compare(QDir::fromNativeSeparators(right), Qt::CaseInsensitive) == 0;
}

ImageBrowserBackend::ImageBrowserBackend(QObject *parent,
                                         const QString &settingsOrganization,
                                         const QString &settingsApplication)
    : QObject(parent)
    , m_settingsOrganization(settingsOrganization)
    , m_settingsApplication(settingsApplication)
{
    m_aestheticEvaluator = new AestheticEvaluator(this);
    connect(m_aestheticEvaluator, &AestheticEvaluator::scoreReady,
            this, &ImageBrowserBackend::onAestheticScoreReady);
    connect(m_aestheticEvaluator, &AestheticEvaluator::scoreFailed,
            this, &ImageBrowserBackend::onAestheticScoreFailed);
    connect(m_aestheticEvaluator, &AestheticEvaluator::availabilityChanged,
            this, &ImageBrowserBackend::onAestheticAvailabilityChanged);
    connect(m_aestheticEvaluator, &AestheticEvaluator::busyChanged,
            this, &ImageBrowserBackend::onAestheticBusyChanged);
    m_aestheticAvailable = m_aestheticEvaluator->isAvailable();
    m_aestheticStatusHint = m_aestheticEvaluator->statusHint();

    m_critiqueEvaluator = new CritiqueEvaluator(this);
    connect(m_critiqueEvaluator, &CritiqueEvaluator::critiqueReady,
            this, &ImageBrowserBackend::onCritiqueReady);
    connect(m_critiqueEvaluator, &CritiqueEvaluator::critiqueFailed,
            this, &ImageBrowserBackend::onCritiqueFailed);
    connect(m_critiqueEvaluator, &CritiqueEvaluator::busyChanged,
            this, &ImageBrowserBackend::onCritiqueBusyChanged);

    m_assistantEvaluator = new AssistantEvaluator(this);
    connect(m_assistantEvaluator, &AssistantEvaluator::replyReady,
            this, &ImageBrowserBackend::onAssistantReplyReady);
    connect(m_assistantEvaluator, &AssistantEvaluator::replyFailed,
            this, &ImageBrowserBackend::onAssistantReplyFailed);
    connect(m_assistantEvaluator, &AssistantEvaluator::busyChanged,
            this, &ImageBrowserBackend::onAssistantBusyChanged);
    connect(m_assistantEvaluator, &AssistantEvaluator::welcomeMessageChanged,
            this, &ImageBrowserBackend::onAssistantWelcomeMessageChanged);

    loadRecentFoldersFromSettings();
}

void ImageBrowserBackend::loadFolder(const QString &folderPath)
{
    m_currentFolder = folderPath;
    loadImagesFromFolder(folderPath);
}

void ImageBrowserBackend::setSettingsScope(const QString &organization, const QString &application)
{
    m_settingsOrganization = organization;
    m_settingsApplication = application;
}

void ImageBrowserBackend::setExportDestRoot(const QString &root)
{
    m_exportDestRoot = root;
}

void ImageBrowserBackend::setFolderPicker(const std::function<QString()> &picker)
{
    m_folderPicker = picker;
}

void ImageBrowserBackend::setAestheticMockScorer(const std::function<double(const QString &)> &scorer)
{
    if (m_aestheticEvaluator)
        m_aestheticEvaluator->setMockScorer(scorer);
    onAestheticAvailabilityChanged(m_aestheticEvaluator && m_aestheticEvaluator->isAvailable());
}

void ImageBrowserBackend::setCritiqueMockGenerator(const std::function<QString(const QString &)> &generator)
{
    if (m_critiqueEvaluator)
        m_critiqueEvaluator->setMockGenerator(generator);
}

void ImageBrowserBackend::setAssistantMockResponder(
    const std::function<QString(const QString &, const QVariantList &)> &responder)
{
    if (m_assistantEvaluator)
        m_assistantEvaluator->setMockResponder(responder);
}

void ImageBrowserBackend::selectFolder()
{
    QString folder;
    if (m_folderPicker) {
        folder = m_folderPicker();
    } else {
        folder = QFileDialog::getExistingDirectory(nullptr,
                                                   u8msg(u8"选择照片文件夹"),
                                                   QStandardPaths::writableLocation(QStandardPaths::PicturesLocation));
    }
    if (folder.isEmpty()) return;

    m_currentFolder = folder;
    loadImagesFromFolder(folder);
}

void ImageBrowserBackend::loadRecentFoldersFromSettings()
{
    QSettings settings(m_settingsOrganization, m_settingsApplication);
    m_recentFolders = settings.value("RecentFolders").toStringList();
}

void ImageBrowserBackend::saveRecentFoldersToSettings()
{
    QSettings settings(m_settingsOrganization, m_settingsApplication);
    settings.setValue("RecentFolders", m_recentFolders);
}

void ImageBrowserBackend::loadImagesFromFolder(const QString &folder)
{
    QDir dir(folder);
    if (!dir.exists()) {
        m_recentFolders.removeAll(folder);
        saveRecentFoldersToSettings();
        emit recentFoldersChanged();
        emit showMessage(u8msg(u8"文件夹不存在或已被删除"));
        return;
    }

    m_recentFolders.removeAll(folder);
    m_recentFolders.prepend(folder);
    while (m_recentFolders.size() > 5) {
        m_recentFolders.removeLast();
    }
    saveRecentFoldersToSettings();
    emit recentFoldersChanged();

    dir.setNameFilters(IMAGE_SUFFIXES);
    dir.setFilter(QDir::Files | QDir::NoDotAndDotDot);

    QFileInfoList fileList = dir.entryInfoList();
    QStringList imageFiles;
    imageFiles.reserve(fileList.size());

    for (const QFileInfo &fileInfo : fileList) {
        imageFiles.append(fileInfo.absoluteFilePath());
    }

    m_imagePaths = imageFiles;

    m_favorites.clear();
    loadFavoritesLog();

    int savedIndex = loadProgress();
    if (savedIndex >= 0 && savedIndex < m_imagePaths.size()) {
        m_currentIndex = savedIndex;
    } else {
        m_currentIndex = m_imagePaths.isEmpty() ? -1 : 0;
    }

    emit imagePathsChanged();
    emit totalCountChanged();
    emit favoriteCountChanged();

    updateCurrentImagePath();
}

QString ImageBrowserBackend::currentImagePath() const
{
    if (m_currentIndex >= 0 && m_currentIndex < m_imagePaths.size())
        return m_imagePaths[m_currentIndex];
    return QString();
}

bool ImageBrowserBackend::isCurrentFavorite() const
{
    return m_favorites.contains(currentImagePath());
}

void ImageBrowserBackend::updateCurrentImagePath()
{
    emit currentImagePathChanged();
    emit isCurrentFavoriteChanged();
    emit currentIndexChanged();
    requestAestheticScore();
    syncCritiqueForCurrentImage();
}

void ImageBrowserBackend::resetAestheticState()
{
    m_aestheticScore = 0.0;
    m_aestheticScoreValid = false;
    setAestheticEvaluating(false);
    emit aestheticScoreChanged();
}

void ImageBrowserBackend::setAestheticEvaluating(bool evaluating)
{
    if (m_aestheticEvaluating == evaluating)
        return;
    m_aestheticEvaluating = evaluating;
    emit aestheticEvaluatingChanged();
}

void ImageBrowserBackend::requestAestheticScore()
{
    const QString path = currentImagePath();
    if (path.isEmpty() || !m_aestheticEvaluator) {
        resetAestheticState();
        return;
    }

    if (m_aestheticEvaluator->hasCachedScore(path)) {
        m_aestheticScore = m_aestheticEvaluator->cachedScore(path);
        m_aestheticScoreValid = true;
        setAestheticEvaluating(false);
        emit aestheticScoreChanged();
        return;
    }

    m_aestheticScoreValid = false;
    emit aestheticScoreChanged();
    setAestheticEvaluating(true);
    m_aestheticEvaluator->requestScore(path);
}

void ImageBrowserBackend::onAestheticScoreReady(const QString &imagePath, double score)
{
    if (!sameImagePath(imagePath, currentImagePath()))
        return;

    m_aestheticScore = score;
    m_aestheticScoreValid = true;
    m_aestheticStatusHint.clear();
    setAestheticEvaluating(false);
    emit aestheticScoreChanged();
    emit aestheticStatusHintChanged();
}

void ImageBrowserBackend::onAestheticScoreFailed(const QString &imagePath, const QString &reason)
{
    if (!sameImagePath(imagePath, currentImagePath()))
        return;

    if (!reason.isEmpty() && m_aestheticStatusHint != reason) {
        m_aestheticStatusHint = reason;
        emit aestheticStatusHintChanged();
    }

    m_aestheticScoreValid = false;
    setAestheticEvaluating(false);
    emit aestheticScoreChanged();
}

void ImageBrowserBackend::onAestheticAvailabilityChanged(bool available)
{
    const QString hint = m_aestheticEvaluator ? m_aestheticEvaluator->statusHint() : QString();
    if (m_aestheticStatusHint != hint) {
        m_aestheticStatusHint = hint;
        emit aestheticStatusHintChanged();
    }

    if (m_aestheticAvailable == available)
        return;
    m_aestheticAvailable = available;
    emit aestheticAvailableChanged();
}

void ImageBrowserBackend::onAestheticBusyChanged(bool busy)
{
    if (currentImagePath().isEmpty())
        return;
    setAestheticEvaluating(busy);
}

void ImageBrowserBackend::syncCritiqueForCurrentImage()
{
    const QString path = currentImagePath();
    if (path.isEmpty() || !m_critiqueEvaluator) {
        m_critiqueText.clear();
        m_critiqueValid = false;
        m_critiqueQualityScoreValid = false;
        setCritiqueEvaluating(false);
        emit critiqueTextChanged();
        return;
    }

    if (m_critiquePanelOpen) {
        requestCritique();
        return;
    }

    if (m_critiqueEvaluator->hasCachedCritique(path)) {
        m_critiqueText = m_critiqueEvaluator->cachedCritique(path);
        m_critiqueValid = true;
        const double qsitScore = m_critiqueEvaluator->cachedCritiqueScore(path);
        m_critiqueQualityScoreValid = qsitScore >= 0.0;
        m_critiqueQualityScore = m_critiqueQualityScoreValid ? qsitScore : 0.0;
        setCritiqueEvaluating(false);
        emit critiqueTextChanged();
        return;
    }

    m_critiqueText.clear();
    m_critiqueValid = false;
    m_critiqueQualityScoreValid = false;
    setCritiqueEvaluating(false);
    emit critiqueTextChanged();
}

void ImageBrowserBackend::setCritiqueEvaluating(bool evaluating)
{
    if (m_critiqueEvaluating == evaluating)
        return;
    m_critiqueEvaluating = evaluating;
    emit critiqueEvaluatingChanged();
}

void ImageBrowserBackend::requestCritique()
{
    const QString path = currentImagePath();
    if (path.isEmpty() || !m_critiqueEvaluator)
        return;

    if (m_critiqueEvaluator->hasCachedCritique(path)) {
        m_critiqueText = m_critiqueEvaluator->cachedCritique(path);
        m_critiqueValid = true;
        const double qsitScore = m_critiqueEvaluator->cachedCritiqueScore(path);
        m_critiqueQualityScoreValid = qsitScore >= 0.0;
        m_critiqueQualityScore = m_critiqueQualityScoreValid ? qsitScore : 0.0;
        setCritiqueEvaluating(false);
        emit critiqueTextChanged();
        return;
    }

    m_critiqueText.clear();
    m_critiqueValid = false;
    m_critiqueQualityScoreValid = false;
    emit critiqueTextChanged();
    setCritiqueEvaluating(true);
    m_critiqueEvaluator->requestCritique(path);
}

void ImageBrowserBackend::onCritiqueReady(const QString &imagePath, const QString &text, double qsitScore)
{
    if (!sameImagePath(imagePath, currentImagePath()))
        return;

    m_critiqueText = text;
    m_critiqueValid = true;
    m_critiqueQualityScoreValid = qsitScore >= 0.0;
    m_critiqueQualityScore = m_critiqueQualityScoreValid ? qsitScore : 0.0;
    m_critiqueStatusHint.clear();
    setCritiqueEvaluating(false);
    emit critiqueTextChanged();
    emit critiqueStatusHintChanged();
}

void ImageBrowserBackend::onCritiqueFailed(const QString &imagePath, const QString &reason)
{
    if (!sameImagePath(imagePath, currentImagePath()))
        return;

    if (!reason.isEmpty() && m_critiqueStatusHint != reason) {
        m_critiqueStatusHint = reason;
        emit critiqueStatusHintChanged();
    }

    m_critiqueValid = false;
    m_critiqueQualityScoreValid = false;
    setCritiqueEvaluating(false);
    emit critiqueTextChanged();
}

void ImageBrowserBackend::onCritiqueBusyChanged(bool busy)
{
    if (currentImagePath().isEmpty())
        return;
    setCritiqueEvaluating(busy);
}

void ImageBrowserBackend::setCritiquePanelOpen(bool open)
{
    if (m_critiquePanelOpen == open)
        return;
    m_critiquePanelOpen = open;
    emit critiquePanelOpenChanged();
    if (open)
        requestCritique();
}

void ImageBrowserBackend::openCritiquePanel()
{
    setCritiquePanelOpen(true);
}

void ImageBrowserBackend::appendAssistantMessage(const QString &role, const QString &text)
{
    if (text.isEmpty())
        return;
    QVariantMap entry;
    entry.insert(QStringLiteral("role"), role);
    entry.insert(QStringLiteral("text"), text);
    m_assistantMessages.append(entry);
    emit assistantMessagesChanged();
}

void ImageBrowserBackend::ensureAssistantWelcome()
{
    if (!m_assistantMessages.isEmpty())
        return;
    const QString welcome = m_assistantEvaluator
                                ? m_assistantEvaluator->welcomeMessage()
                                : QString();
    if (!welcome.isEmpty()) {
        appendAssistantMessage(QStringLiteral("assistant"), welcome);
        return;
    }
    appendAssistantMessage(QStringLiteral("assistant"),
                           u8msg(u8"你好，我是 ImageBrowser 小助理。可以问我快捷键、收藏导出、"
                                 u8"美学评分、AI 点评、安装构建等问题。"));
}

void ImageBrowserBackend::setAssistantPanelOpen(bool open)
{
    if (m_assistantPanelOpen == open)
        return;
    m_assistantPanelOpen = open;
    emit assistantPanelOpenChanged();
    if (open)
        ensureAssistantWelcome();
}

void ImageBrowserBackend::openAssistantPanel()
{
    setAssistantPanelOpen(true);
}

void ImageBrowserBackend::clearAssistantChat()
{
    if (m_assistantMessages.isEmpty())
        return;
    m_assistantMessages.clear();
    emit assistantMessagesChanged();
    ensureAssistantWelcome();
}

void ImageBrowserBackend::sendAssistantMessage(const QString &text)
{
    const QString trimmed = text.trimmed();
    if (trimmed.isEmpty() || !m_assistantEvaluator)
        return;

    appendAssistantMessage(QStringLiteral("user"), trimmed);
    setAssistantBusy(true);
    m_assistantStatusHint.clear();
    emit assistantStatusHintChanged();

    QVariantList history = m_assistantMessages;
    m_assistantEvaluator->sendMessage(trimmed, history);
}

void ImageBrowserBackend::setAssistantBusy(bool busy)
{
    if (m_assistantBusy == busy)
        return;
    m_assistantBusy = busy;
    emit assistantBusyChanged();
}

void ImageBrowserBackend::onAssistantReplyReady(const QString &reply)
{
    setAssistantBusy(false);
    m_assistantStatusHint.clear();
    emit assistantStatusHintChanged();
    appendAssistantMessage(QStringLiteral("assistant"), reply);
}

void ImageBrowserBackend::onAssistantReplyFailed(const QString &reason)
{
    setAssistantBusy(false);
    if (!reason.isEmpty() && m_assistantStatusHint != reason) {
        m_assistantStatusHint = reason;
        emit assistantStatusHintChanged();
    }
    appendAssistantMessage(QStringLiteral("assistant"),
                           reason.isEmpty()
                               ? u8msg(u8"小助理暂时无法回答，请稍后再试。")
                               : reason);
}

void ImageBrowserBackend::onAssistantBusyChanged(bool busy)
{
    setAssistantBusy(busy);
}

void ImageBrowserBackend::onAssistantWelcomeMessageChanged()
{
    if (m_assistantPanelOpen && m_assistantMessages.isEmpty())
        ensureAssistantWelcome();
}

void ImageBrowserBackend::setCurrentIndex(int index)
{
    if (index >= 0 && index < m_imagePaths.size() && index != m_currentIndex) {
        m_currentIndex = index;
        updateCurrentImagePath();
        saveProgress();
    }
}

void ImageBrowserBackend::nextImage()
{
    if (m_imagePaths.isEmpty()) return;
    setCurrentIndex((m_currentIndex + 1) % m_imagePaths.size());
}

void ImageBrowserBackend::previousImage()
{
    if (m_imagePaths.isEmpty()) return;
    setCurrentIndex((m_currentIndex - 1 + m_imagePaths.size()) % m_imagePaths.size());
}

void ImageBrowserBackend::toggleFavoriteForCurrent()
{
    QString path = currentImagePath();
    if (path.isEmpty()) return;

    QString fileName = QFileInfo(path).fileName();
    if (m_favorites.contains(path)) {
        m_favorites.remove(path);
        emit showMessage(u8msg(u8"已取消收藏: %1").arg(fileName), QStringLiteral("unfav"));
    } else {
        m_favorites.insert(path);
        emit showMessage(u8msg(u8"已收藏: %1").arg(fileName), QStringLiteral("fav"));
    }

    saveFavoritesLog();
    emit favoriteCountChanged();
    emit isCurrentFavoriteChanged();
}

void ImageBrowserBackend::saveProgress()
{
    if (m_currentFolder.isEmpty() || m_currentIndex < 0) return;

    QSettings settings(m_currentFolder + "/browser_config.ini", QSettings::IniFormat);
    settings.setValue("LastIndex", m_currentIndex);
    settings.setValue("LastFileName", QFileInfo(currentImagePath()).fileName());
}

int ImageBrowserBackend::loadProgress()
{
    QString configPath = m_currentFolder + "/browser_config.ini";
    if (!QFile::exists(configPath)) return -1;

    QSettings settings(configPath, QSettings::IniFormat);
    int savedIndex = settings.value("LastIndex", -1).toInt();
    QString savedName = settings.value("LastFileName", "").toString();

    if (!savedName.isEmpty()) {
        for (int i = 0; i < m_imagePaths.size(); ++i) {
            if (QFileInfo(m_imagePaths[i]).fileName() == savedName) {
                return i;
            }
        }
    }
    return savedIndex;
}

void ImageBrowserBackend::saveFavoritesLog()
{
    if (m_currentFolder.isEmpty()) return;
    QFile file(m_currentFolder + "/favorites.txt");
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        out.setCodec("UTF-8");
        for (const QString &path : m_favorites) {
            out << QFileInfo(path).fileName() << "\n";
        }
    }
}

void ImageBrowserBackend::loadFavoritesLog()
{
    QFile file(m_currentFolder + "/favorites.txt");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;

    QTextStream in(&file);
    in.setCodec("UTF-8");
    while (!in.atEnd()) {
        QString fileName = in.readLine().trimmed();
        if (fileName.isEmpty()) continue;

        QString fullPath = m_currentFolder + "/" + fileName;
        if (QFile::exists(fullPath)) {
            m_favorites.insert(fullPath);
        }
    }
}

void ImageBrowserBackend::exportFavorites()
{
    if (m_favorites.isEmpty()) {
        emit showMessage(u8msg(u8"没有收藏的照片可导出"));
        return;
    }

    QString destRoot = m_exportDestRoot;
    QString folderName = QFileInfo(m_currentFolder).fileName();
    if (folderName.isEmpty()) folderName = u8msg(u8"未知文件夹");
    QString destDir = destRoot + "/" + folderName;

    QDir dir;
    if (!dir.mkpath(destDir)) {
        emit showMessage(u8msg(u8"无法创建目录: %1").arg(destDir));
        return;
    }

    QSet<QString> favoritesCopy = m_favorites;

    QtConcurrent::run([this, favoritesCopy, destDir]() {
        int successCount = 0;
        for (const QString &srcPath : favoritesCopy) {
            QFileInfo fileInfo(srcPath);
            QString destPath = destDir + "/" + fileInfo.fileName();

            if (!QFile::exists(destPath)) {
                if (QFile::copy(srcPath, destPath)) {
                    successCount++;
                }
            }
        }
        QMetaObject::invokeMethod(this, "notifyExportComplete", Qt::QueuedConnection,
                                  Q_ARG(int, successCount),
                                  Q_ARG(QString, destDir));
    });
}

void ImageBrowserBackend::notifyExportComplete(int successCount, const QString &destDir)
{
    emit showMessage(u8msg(u8"导出完成，成功复制 %1 张照片到 %2")
                         .arg(successCount)
                         .arg(destDir),
                     QStringLiteral("info"));
}
