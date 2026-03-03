#include "ImageBrowserBackend.h"
#include <QFileDialog>
#include <QDir>
#include <QStandardPaths>
#include <QFileInfo>
#include <QDebug>
#include <QtConcurrent>
#include <QSettings>

static const QStringList IMAGE_SUFFIXES = {"*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.webp"};

ImageBrowserBackend::ImageBrowserBackend(QObject *parent) : QObject(parent)
{
}

// --- 文件夹与图片加载逻辑 ---

void ImageBrowserBackend::selectFolder()
{
    QString folder = QFileDialog::getExistingDirectory(nullptr,
                                                       tr("选择照片文件夹"),
                                                       QStandardPaths::writableLocation(QStandardPaths::PicturesLocation));
    if (folder.isEmpty()) return;

    m_currentFolder = folder;
    loadImagesFromFolder(folder);
}

void ImageBrowserBackend::loadImagesFromFolder(const QString &folder)
{
    QDir dir(folder);
    if (!dir.exists()) return;

    dir.setNameFilters(IMAGE_SUFFIXES);
    dir.setFilter(QDir::Files | QDir::NoDotAndDotDot);

    QFileInfoList fileList = dir.entryInfoList();
    QStringList imageFiles;
    imageFiles.reserve(fileList.size());

    for (const QFileInfo &fileInfo : fileList) {
        imageFiles.append(fileInfo.absoluteFilePath());
    }

    m_imagePaths = imageFiles;

    // 1. 恢复收藏夹数据
    m_favorites.clear();
    loadFavoritesLog();

    // 2. 恢复上次浏览进度
    int savedIndex = loadProgress();
    if (savedIndex >= 0 && savedIndex < m_imagePaths.size()) {
        m_currentIndex = savedIndex;
    } else {
        m_currentIndex = m_imagePaths.isEmpty() ? -1 : 0;
    }

    // 3. 统一触发信号更新 UI
    updateCurrentImagePath();

    emit imagePathsChanged();
    emit totalCountChanged();
    emit favoriteCountChanged();
}

// --- 核心状态控制 ---

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

        // 每次切换图片时实时保存当前进度
        saveProgress();
    }
}

// --- 交互功能 ---

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
        emit showMessage(tr("已取消收藏: %1").arg(fileName));
    } else {
        m_favorites.insert(path);
        emit showMessage(tr("已收藏: %1").arg(fileName));
    }

    saveFavoritesLog();
    emit favoriteCountChanged();
    emit isCurrentFavoriteChanged();
}

// --- 配置持久化逻辑 (进度与收藏) ---

void ImageBrowserBackend::saveProgress()
{
    if (m_currentFolder.isEmpty() || m_currentIndex < 0) return;

    // 在文件夹内创建隐藏配置
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

    // 优先匹配文件名，防止因外部增删文件导致的索引偏移
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
    while (!in.atEnd()) {
        QString fileName = in.readLine().trimmed();
        if (fileName.isEmpty()) continue;

        QString fullPath = m_currentFolder + "/" + fileName;
        if (QFile::exists(fullPath)) {
            m_favorites.insert(fullPath);
        }
    }
}

// --- 异步导出 ---

void ImageBrowserBackend::exportFavorites()
{
    if (m_favorites.isEmpty()) {
        emit showMessage(tr("没有收藏的照片可导出"));
        return;
    }

    QString destRoot = "D:/收藏";
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
        emit showMessage(tr("导出完成，成功复制 %1 张照片到 %2").arg(successCount).arg(destDir));
    });
}
