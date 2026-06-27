#ifndef IMAGEBROWSERBACKEND_H
#define IMAGEBROWSERBACKEND_H

#include <QObject>
#include <QStringList>
#include <QSet>
#include <functional>

class AestheticEvaluator;
class CritiqueEvaluator;

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
    Q_PROPERTY(double aestheticScore READ aestheticScore NOTIFY aestheticScoreChanged)
    Q_PROPERTY(bool aestheticScoreValid READ aestheticScoreValid NOTIFY aestheticScoreChanged)
    Q_PROPERTY(bool aestheticEvaluating READ aestheticEvaluating NOTIFY aestheticEvaluatingChanged)
    Q_PROPERTY(bool aestheticAvailable READ aestheticAvailable NOTIFY aestheticAvailableChanged)
    Q_PROPERTY(QString aestheticStatusHint READ aestheticStatusHint NOTIFY aestheticStatusHintChanged)
    Q_PROPERTY(QString critiqueText READ critiqueText NOTIFY critiqueTextChanged)
    Q_PROPERTY(bool critiqueValid READ critiqueValid NOTIFY critiqueTextChanged)
    Q_PROPERTY(double critiqueQualityScore READ critiqueQualityScore NOTIFY critiqueTextChanged)
    Q_PROPERTY(bool critiqueQualityScoreValid READ critiqueQualityScoreValid NOTIFY critiqueTextChanged)
    Q_PROPERTY(bool critiqueEvaluating READ critiqueEvaluating NOTIFY critiqueEvaluatingChanged)
    Q_PROPERTY(QString critiqueStatusHint READ critiqueStatusHint NOTIFY critiqueStatusHintChanged)
    Q_PROPERTY(bool critiquePanelOpen READ critiquePanelOpen WRITE setCritiquePanelOpen NOTIFY critiquePanelOpenChanged)

public:
    explicit ImageBrowserBackend(QObject *parent = nullptr,
                                 const QString &settingsOrganization = QStringLiteral("WangChang"),
                                 const QString &settingsApplication = QStringLiteral("ImageBrowser"));

    QStringList imagePaths() const { return m_imagePaths; }
    int currentIndex() const { return m_currentIndex; }
    QString currentImagePath() const;
    int totalCount() const { return m_imagePaths.size(); }
    int favoriteCount() const { return m_favorites.size(); }

    void setCurrentIndex(int index);
    bool isCurrentFavorite() const;

    double aestheticScore() const { return m_aestheticScore; }
    bool aestheticScoreValid() const { return m_aestheticScoreValid; }
    bool aestheticEvaluating() const { return m_aestheticEvaluating; }
    bool aestheticAvailable() const { return m_aestheticAvailable; }
    QString aestheticStatusHint() const { return m_aestheticStatusHint; }
    QString critiqueText() const { return m_critiqueText; }
    bool critiqueValid() const { return m_critiqueValid; }
    double critiqueQualityScore() const { return m_critiqueQualityScore; }
    bool critiqueQualityScoreValid() const { return m_critiqueQualityScoreValid; }
    bool critiqueEvaluating() const { return m_critiqueEvaluating; }
    QString critiqueStatusHint() const { return m_critiqueStatusHint; }
    bool critiquePanelOpen() const { return m_critiquePanelOpen; }
    void setCritiquePanelOpen(bool open);

    QStringList recentFolders() const { return m_recentFolders; }
    Q_INVOKABLE void loadFolder(const QString &folderPath);

    void setSettingsScope(const QString &organization, const QString &application);
    void setExportDestRoot(const QString &root);
    void setFolderPicker(const std::function<QString()> &picker);
    void setAestheticMockScorer(const std::function<double(const QString &)> &scorer);
    void setCritiqueMockGenerator(const std::function<QString(const QString &)> &generator);

    Q_INVOKABLE void requestCritique();
    Q_INVOKABLE void openCritiquePanel();

public slots:
    void selectFolder();
    void nextImage();
    void previousImage();
    void toggleFavoriteForCurrent();
    void exportFavorites();

private slots:
    void notifyExportComplete(int successCount, const QString &destDir);
    void onAestheticScoreReady(const QString &imagePath, double score);
    void onAestheticScoreFailed(const QString &imagePath, const QString &reason);
    void onAestheticAvailabilityChanged(bool available);
    void onAestheticBusyChanged(bool busy);
    void onCritiqueReady(const QString &imagePath, const QString &text, double qsitScore);
    void onCritiqueFailed(const QString &imagePath, const QString &reason);
    void onCritiqueBusyChanged(bool busy);

signals:
    void imagePathsChanged();
    void currentIndexChanged();
    void currentImagePathChanged();
    void totalCountChanged();
    void favoriteCountChanged();
    void showMessage(const QString &msg, const QString &type = QStringLiteral("info"));
    void isCurrentFavoriteChanged();
    void recentFoldersChanged();
    void aestheticScoreChanged();
    void aestheticEvaluatingChanged();
    void aestheticAvailableChanged();
    void aestheticStatusHintChanged();
    void critiqueTextChanged();
    void critiqueEvaluatingChanged();
    void critiqueStatusHintChanged();
    void critiquePanelOpenChanged();

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

    QString m_settingsOrganization = QStringLiteral("WangChang");
    QString m_settingsApplication = QStringLiteral("ImageBrowser");
    QString m_exportDestRoot = QStringLiteral("D:/收藏");
    std::function<QString()> m_folderPicker;

    void loadRecentFoldersFromSettings();
    void saveRecentFoldersToSettings();
    void requestAestheticScore();
    void resetAestheticState();
    void setAestheticEvaluating(bool evaluating);
    void syncCritiqueForCurrentImage();
    void setCritiqueEvaluating(bool evaluating);

    AestheticEvaluator *m_aestheticEvaluator = nullptr;
    CritiqueEvaluator *m_critiqueEvaluator = nullptr;
    double m_aestheticScore = 0.0;
    bool m_aestheticScoreValid = false;
    bool m_aestheticEvaluating = false;
    bool m_aestheticAvailable = false;
    QString m_aestheticStatusHint;
    QString m_critiqueText;
    bool m_critiqueValid = false;
    double m_critiqueQualityScore = 0.0;
    bool m_critiqueQualityScoreValid = false;
    bool m_critiqueEvaluating = false;
    QString m_critiqueStatusHint;
    bool m_critiquePanelOpen = false;
};

#endif // IMAGEBROWSERBACKEND_H
