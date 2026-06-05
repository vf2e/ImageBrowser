#ifndef IMAGEBROWSERBACKEND_H
#define IMAGEBROWSERBACKEND_H

#include <QObject>
#include <QStringList>
#include <QSet>

class ImageBrowserBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList imagePaths READ imagePaths NOTIFY imagePathsChanged)
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(QString currentImagePath READ currentImagePath NOTIFY currentImagePathChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY totalCountChanged)
    Q_PROPERTY(int favoriteCount READ favoriteCount NOTIFY favoriteCountChanged)
    Q_PROPERTY(bool isCurrentFavorite READ isCurrentFavorite NOTIFY isCurrentFavoriteChanged)
    Q_PROPERTY(QStringList recentFolders READ recentFolders NOTIFY recentFoldersChanged)

public:
    explicit ImageBrowserBackend(QObject *parent = nullptr);

    QStringList imagePaths() const { return m_imagePaths; }
    int currentIndex() const { return m_currentIndex; }
    QString currentImagePath() const;
    int totalCount() const { return m_imagePaths.size(); }
    int favoriteCount() const { return m_favorites.size(); }

    void setCurrentIndex(int index);
    bool isCurrentFavorite() const;

    QStringList recentFolders() const { return m_recentFolders; }
    Q_INVOKABLE void loadFolder(const QString &folderPath);

public slots:
    void selectFolder();
    void nextImage();
    void previousImage();
    void toggleFavoriteForCurrent();
    void exportFavorites();

private slots:
    void notifyExportComplete(int successCount, const QString &destDir);

signals:
    void imagePathsChanged();
    void currentIndexChanged();
    void currentImagePathChanged();
    void totalCountChanged();
    void favoriteCountChanged();
    void showMessage(const QString &msg, const QString &type = QStringLiteral("info"));
    void isCurrentFavoriteChanged();
    void recentFoldersChanged();

private:
    QStringList m_imagePaths;
    int m_currentIndex = -1;
    QSet<QString> m_favorites;
    QString m_currentFolder;

    void loadImagesFromFolder(const QString &folder);
    void updateCurrentImagePath();

    void saveFavoritesLog();
    void loadFavoritesLog();
    void saveProgress();
    int loadProgress();

    QStringList m_recentFolders;

    void loadRecentFoldersFromSettings();
    void saveRecentFoldersToSettings();
};

#endif // IMAGEBROWSERBACKEND_H
