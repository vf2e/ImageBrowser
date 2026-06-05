#include "ImageBrowserBackend.h"
#include <QFileDialog>
#include <QDir>
#include <QStandardPaths>
#include <QFileInfo>
#include <QDebug>
#include <QtConcurrent>
#include <QSettings>
#include <QTextStream>

static const QStringList IMAGE_SUFFIXES = {"*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.webp"};

ImageBrowserBackend::ImageBrowserBackend(QObject *parent,
                                         const QString &settingsOrganization,
                                         const QString &settingsApplication)
    : QObject(parent)
    , m_settingsOrganization(settingsOrganization)
    , m_settingsApplication(settingsApplication)
{
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

void ImageBrowserBackend::selectFolder()
{
    QString folder;
    if (m_folderPicker) {
        folder = m_folderPicker();
    } else {
        folder = QFileDialog::getExistingDirectory(nullptr,
                                                   tr("选择照片文件夹"),
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
        emit showMessage(tr("文件夹不存在或已被删除"));
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
        emit showMessage(QString::fromUtf8(u8"已取消收藏: %1").arg(fileName), QStringLiteral("unfav"));
    } else {
        m_favorites.insert(path);
        emit showMessage(QString::fromUtf8(u8"已收藏: %1").arg(fileName), QStringLiteral("fav"));
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
        emit showMessage(tr("没有收藏的照片可导出"));
        return;
    }

    QString destRoot = m_exportDestRoot;
    QString folderName = QFileInfo(m_currentFolder).fileName();
    if (folderName.isEmpty()) folderName = "未知文件夹";
    QString destDir = destRoot + "/" + folderName;

    QDir dir;
    if (!dir.mkpath(destDir)) {
        emit showMessage(tr("无法创建目录: %1").arg(destDir));
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
    emit showMessage(QString::fromUtf8(u8"导出完成，成功复制 %1 张照片到 %2")
                         .arg(successCount)
                         .arg(destDir),
                     QStringLiteral("info"));
}
