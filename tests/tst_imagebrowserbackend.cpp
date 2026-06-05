#include <QtTest>
#include <QSignalSpy>
#include <QSettings>
#include <QFileInfo>
#include <QThread>
#include <QUuid>

#include "TestFixture.h"

class TestImageBrowserBackend : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();

    // --- 初始状态 ---
    void initialState_isEmpty();
    void currentImagePath_returnsEmptyWhenNoImages();

    // --- 文件夹加载 ---
    void loadFolder_emptyFolder_hasZeroImages();
    void loadFolder_readsSupportedImageExtensions();
    void loadFolder_ignoresUnsupportedFiles();
    void loadFolder_nonexistentFolder_emitsMessageAndRemovesFromRecent();
    void loadFolder_emptyFolder_currentIndexIsMinusOne();
    void loadFolder_withImages_currentIndexStartsAtZero();

    // --- 索引与导航 ---
    void setCurrentIndex_updatesCurrentImagePath();
    void setCurrentIndex_ignoresInvalidIndices();
    void setCurrentIndex_sameIndex_doesNotChangeState();
    void nextImage_wrapsAroundAtEnd();
    void previousImage_wrapsAroundAtStart();
    void nextImage_onEmptyFolder_doesNothing();
    void previousImage_onEmptyFolder_doesNothing();

    // --- 收藏 ---
    void toggleFavorite_addsCurrentImage();
    void toggleFavorite_removesCurrentImage();
    void toggleFavorite_emitsFavMessageType();
    void toggleFavorite_emitsUnfavMessageType();
    void toggleFavorite_onEmptyFolder_doesNothing();
    void isCurrentFavorite_reflectsFavoriteState();

    // --- 收藏持久化 ---
    void favorites_persistToUtf8File();
    void favorites_reloadAfterFolderReopen();
    void favorites_ignoreMissingFilesInLog();
    void favorites_supportChineseFileNames();

    // --- 浏览进度持久化 ---
    void progress_savedOnIndexChange();
    void progress_restoredByFileNameWhenIndexShifted();
    void progress_restoredBySavedIndexWhenFileNameMissing();

    // --- 最近文件夹 ---
    void recentFolders_prependsLoadedFolder();
    void recentFolders_deduplicatesExistingEntry();
    void recentFolders_keepsAtMostFiveEntries();
    void recentFolders_persistAcrossInstances();

    // --- 导出 ---
    void exportFavorites_withNoFavorites_emitsInfoMessage();
    void exportFavorites_copiesFilesToDestination();
    void exportFavorites_skipsExistingDestinationFiles();
    void exportFavorites_completesAsynchronously();

    // --- 信号 ---
    void loadFolder_emitsStateChangeSignals();
    void setCurrentIndex_emitsCurrentIndexChanged();
    void loadFolder_emitsRecentFoldersChanged();
    void toggleFavorite_emitsIsCurrentFavoriteChanged();
    void loadFolder_emitsCurrentIndexChanged();

    // --- selectFolder（注入式） ---
    void selectFolder_usesInjectedPicker();
    void selectFolder_emptyPickerResult_doesNothing();

    // --- 多收藏与文件夹隔离 ---
    void favorites_multipleImages_trackedIndependently();
    void favorites_isolatedPerFolder();

    // --- 导出异常 ---
    void exportFavorites_mkpathFailure_emitsMessage();

    // --- 集成工作流 ---
    void workflow_loadNavigateFavoriteAndExport();
};

void TestImageBrowserBackend::initTestCase()
{
    QCoreApplication::setOrganizationName(QStringLiteral("ImageBrowserTests"));
    QCoreApplication::setApplicationName(QStringLiteral("GlobalTestCase"));
}

void TestImageBrowserBackend::cleanupTestCase()
{
    QSettings(QStringLiteral("ImageBrowserTests"), QStringLiteral("GlobalTestCase")).clear();
}

void TestImageBrowserBackend::initialState_isEmpty()
{
    TestFixture fixture;
    QVERIFY(fixture.isValid());

    ImageBrowserBackend *backend = fixture.backend();
    QCOMPARE(backend->totalCount(), 0);
    QCOMPARE(backend->currentIndex(), -1);
    QCOMPARE(backend->favoriteCount(), 0);
    QVERIFY(!backend->isCurrentFavorite());
    QVERIFY(backend->imagePaths().isEmpty());
}

void TestImageBrowserBackend::currentImagePath_returnsEmptyWhenNoImages()
{
    TestFixture fixture;
    QVERIFY(fixture.isValid());
    QVERIFY(fixture.backend()->currentImagePath().isEmpty());
}

void TestImageBrowserBackend::loadFolder_emptyFolder_hasZeroImages()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("empty"));

    fixture.backend()->loadFolder(folder);

    QCOMPARE(fixture.backend()->totalCount(), 0);
    QCOMPARE(fixture.backend()->currentIndex(), -1);
}

void TestImageBrowserBackend::loadFolder_readsSupportedImageExtensions()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("mixed"));

    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.createImageFile(folder, QStringLiteral("b.jpeg"));
    fixture.createImageFile(folder, QStringLiteral("c.png"));
    fixture.createImageFile(folder, QStringLiteral("d.bmp"));
    fixture.createImageFile(folder, QStringLiteral("e.gif"));
    fixture.createImageFile(folder, QStringLiteral("f.webp"));

    fixture.backend()->loadFolder(folder);

    QCOMPARE(fixture.backend()->totalCount(), 6);
}

void TestImageBrowserBackend::loadFolder_ignoresUnsupportedFiles()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("filtered"));

    fixture.createImageFile(folder, QStringLiteral("photo.jpg"));
    fixture.createImageFile(folder, QStringLiteral("notes.txt"));
    fixture.createImageFile(folder, QStringLiteral("video.mp4"));
    fixture.createImageFile(folder, QStringLiteral("archive.zip"));

    fixture.backend()->loadFolder(folder);

    QCOMPARE(fixture.backend()->totalCount(), 1);
    QVERIFY(fixture.backend()->currentImagePath().endsWith(QStringLiteral("photo.jpg")));
}

void TestImageBrowserBackend::loadFolder_nonexistentFolder_emitsMessageAndRemovesFromRecent()
{
    TestFixture fixture;
    const QString missing = fixture.rootPath() + QStringLiteral("/missing-folder");

    QSignalSpy messageSpy(fixture.backend(), &ImageBrowserBackend::showMessage);
    fixture.backend()->loadFolder(missing);

    QCOMPARE(messageSpy.count(), 1);
    QCOMPARE(fixture.backend()->totalCount(), 0);
    QVERIFY(!fixture.backend()->recentFolders().contains(missing));
}

void TestImageBrowserBackend::loadFolder_emptyFolder_currentIndexIsMinusOne()
{
    TestFixture fixture;
    fixture.backend()->loadFolder(fixture.createFolder(QStringLiteral("empty")));
    QCOMPARE(fixture.backend()->currentIndex(), -1);
}

void TestImageBrowserBackend::loadFolder_withImages_currentIndexStartsAtZero()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("photos"));
    fixture.createImageFile(folder, QStringLiteral("1.jpg"));
    fixture.createImageFile(folder, QStringLiteral("2.jpg"));

    fixture.backend()->loadFolder(folder);

    QCOMPARE(fixture.backend()->currentIndex(), 0);
    QVERIFY(fixture.backend()->currentImagePath().endsWith(QStringLiteral("1.jpg"))
           || fixture.backend()->currentImagePath().endsWith(QStringLiteral("2.jpg")));
}

void TestImageBrowserBackend::setCurrentIndex_updatesCurrentImagePath()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("nav"));
    const QString first = fixture.createImageFile(folder, QStringLiteral("first.jpg"));
    const QString second = fixture.createImageFile(folder, QStringLiteral("second.jpg"));

    fixture.backend()->loadFolder(folder);
    QCOMPARE(fixture.backend()->currentIndex(), 0);
    QCOMPARE(fixture.backend()->currentImagePath(), first);

    fixture.backend()->setCurrentIndex(1);
    QCOMPARE(fixture.backend()->currentIndex(), 1);
    QCOMPARE(fixture.backend()->currentImagePath(), second);
}

void TestImageBrowserBackend::setCurrentIndex_ignoresInvalidIndices()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("bounds"));
    fixture.createImageFile(folder, QStringLiteral("only.jpg"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->setCurrentIndex(99);
    QCOMPARE(fixture.backend()->currentIndex(), 0);

    fixture.backend()->setCurrentIndex(-1);
    QCOMPARE(fixture.backend()->currentIndex(), 0);
}

void TestImageBrowserBackend::setCurrentIndex_sameIndex_doesNotChangeState()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("same"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.createImageFile(folder, QStringLiteral("b.jpg"));

    fixture.backend()->loadFolder(folder);

    QSignalSpy indexSpy(fixture.backend(), &ImageBrowserBackend::currentIndexChanged);
    fixture.backend()->setCurrentIndex(0);
    QCOMPARE(indexSpy.count(), 0);
}

void TestImageBrowserBackend::nextImage_wrapsAroundAtEnd()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("next"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.createImageFile(folder, QStringLiteral("b.jpg"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->setCurrentIndex(1);
    fixture.backend()->nextImage();

    QCOMPARE(fixture.backend()->currentIndex(), 0);
}

void TestImageBrowserBackend::previousImage_wrapsAroundAtStart()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("prev"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.createImageFile(folder, QStringLiteral("b.jpg"));

    fixture.backend()->loadFolder(folder);
    QCOMPARE(fixture.backend()->currentIndex(), 0);

    fixture.backend()->previousImage();
    QCOMPARE(fixture.backend()->currentIndex(), 1);
}

void TestImageBrowserBackend::nextImage_onEmptyFolder_doesNothing()
{
    TestFixture fixture;
    fixture.backend()->loadFolder(fixture.createFolder(QStringLiteral("empty")));
    fixture.backend()->nextImage();
    QCOMPARE(fixture.backend()->currentIndex(), -1);
}

void TestImageBrowserBackend::previousImage_onEmptyFolder_doesNothing()
{
    TestFixture fixture;
    fixture.backend()->loadFolder(fixture.createFolder(QStringLiteral("empty")));
    fixture.backend()->previousImage();
    QCOMPARE(fixture.backend()->currentIndex(), -1);
}

void TestImageBrowserBackend::toggleFavorite_addsCurrentImage()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("fav"));
    const QString image = fixture.createImageFile(folder, QStringLiteral("star.jpg"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->toggleFavoriteForCurrent();

    QCOMPARE(fixture.backend()->favoriteCount(), 1);
    QVERIFY(fixture.backend()->isCurrentFavorite());
    QCOMPARE(fixture.backend()->currentImagePath(), image);
}

void TestImageBrowserBackend::toggleFavorite_removesCurrentImage()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("unfav"));
    fixture.createImageFile(folder, QStringLiteral("temp.jpg"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->toggleFavoriteForCurrent();
    fixture.backend()->toggleFavoriteForCurrent();

    QCOMPARE(fixture.backend()->favoriteCount(), 0);
    QVERIFY(!fixture.backend()->isCurrentFavorite());
}

void TestImageBrowserBackend::toggleFavorite_emitsFavMessageType()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("fav-msg"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));

    QSignalSpy messageSpy(fixture.backend(), &ImageBrowserBackend::showMessage);
    fixture.backend()->loadFolder(folder);
    fixture.backend()->toggleFavoriteForCurrent();

    QCOMPARE(messageSpy.count(), 1);
    QCOMPARE(messageSpy.at(0).at(1).toString(), QStringLiteral("fav"));
}

void TestImageBrowserBackend::toggleFavorite_emitsUnfavMessageType()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("unfav-msg"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->toggleFavoriteForCurrent();

    QSignalSpy messageSpy(fixture.backend(), &ImageBrowserBackend::showMessage);
    fixture.backend()->toggleFavoriteForCurrent();

    QCOMPARE(messageSpy.count(), 1);
    QCOMPARE(messageSpy.at(0).at(1).toString(), QStringLiteral("unfav"));
}

void TestImageBrowserBackend::toggleFavorite_onEmptyFolder_doesNothing()
{
    TestFixture fixture;
    fixture.backend()->loadFolder(fixture.createFolder(QStringLiteral("empty")));

    QSignalSpy messageSpy(fixture.backend(), &ImageBrowserBackend::showMessage);
    fixture.backend()->toggleFavoriteForCurrent();

    QCOMPARE(messageSpy.count(), 0);
    QCOMPARE(fixture.backend()->favoriteCount(), 0);
}

void TestImageBrowserBackend::isCurrentFavorite_reflectsFavoriteState()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("state"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.createImageFile(folder, QStringLiteral("b.jpg"));

    fixture.backend()->loadFolder(folder);
    QVERIFY(!fixture.backend()->isCurrentFavorite());

    fixture.backend()->toggleFavoriteForCurrent();
    QVERIFY(fixture.backend()->isCurrentFavorite());

    fixture.backend()->setCurrentIndex(1);
    QVERIFY(!fixture.backend()->isCurrentFavorite());
}

void TestImageBrowserBackend::favorites_persistToUtf8File()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("persist"));
    fixture.createImageFile(folder, QStringLiteral("收藏.jpg"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->toggleFavoriteForCurrent();

    const QString favoritesPath = folder + QStringLiteral("/favorites.txt");
    QVERIFY(fixture.fileExists(favoritesPath));
    QCOMPARE(fixture.readTextFile(favoritesPath).trimmed(), QStringLiteral("收藏.jpg"));
}

void TestImageBrowserBackend::favorites_reloadAfterFolderReopen()
{
    TestFixture fixture(QStringLiteral("reload_favorites"));
    const QString folder = fixture.createFolder(QStringLiteral("album"));
    const QString image = fixture.createImageFile(folder, QStringLiteral("keep.png"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->toggleFavoriteForCurrent();

    TestFixture fixture2(QStringLiteral("reload_favorites"));
    fixture2.backend()->loadFolder(folder);

    QCOMPARE(fixture2.backend()->favoriteCount(), 1);
    QCOMPARE(fixture2.backend()->currentImagePath(), image);
    QVERIFY(fixture2.backend()->isCurrentFavorite());
}

void TestImageBrowserBackend::favorites_ignoreMissingFilesInLog()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("missing-log"));
    fixture.createImageFile(folder, QStringLiteral("exists.jpg"));
    fixture.writeTextFile(folder, QStringLiteral("favorites.txt"),
                          QStringLiteral("exists.jpg\nghost.jpg\n"));

    fixture.backend()->loadFolder(folder);

    QCOMPARE(fixture.backend()->favoriteCount(), 1);
}

void TestImageBrowserBackend::favorites_supportChineseFileNames()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("中文目录"));
    fixture.createImageFile(folder, QStringLiteral("风景照片.jpg"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->toggleFavoriteForCurrent();

    TestFixture fixture2;
    fixture2.backend()->loadFolder(folder);
    QCOMPARE(fixture2.backend()->favoriteCount(), 1);
    QVERIFY(fixture2.backend()->currentImagePath().contains(QStringLiteral("风景照片.jpg")));
}

void TestImageBrowserBackend::progress_savedOnIndexChange()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("progress"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.createImageFile(folder, QStringLiteral("b.jpg"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->setCurrentIndex(1);

    QSettings settings(folder + QStringLiteral("/browser_config.ini"), QSettings::IniFormat);
    QCOMPARE(settings.value(QStringLiteral("LastIndex")).toInt(), 1);
    QCOMPARE(settings.value(QStringLiteral("LastFileName")).toString(), QStringLiteral("b.jpg"));
}

void TestImageBrowserBackend::progress_restoredByFileNameWhenIndexShifted()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("restore-name"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.createImageFile(folder, QStringLiteral("target.jpg"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->setCurrentIndex(1);

    fixture.createImageFile(folder, QStringLiteral("new-first.jpg"));
    fixture.backend()->loadFolder(folder);

    QVERIFY(fixture.backend()->currentImagePath().endsWith(QStringLiteral("target.jpg")));
}

void TestImageBrowserBackend::progress_restoredBySavedIndexWhenFileNameMissing()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("restore-index"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.createImageFile(folder, QStringLiteral("b.jpg"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->setCurrentIndex(1);

    QFile::remove(folder + QStringLiteral("/b.jpg"));
    fixture.backend()->loadFolder(folder);

    QCOMPARE(fixture.backend()->currentIndex(), 0);
}

void TestImageBrowserBackend::recentFolders_prependsLoadedFolder()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("album-a"));

    fixture.backend()->loadFolder(folder);

    QCOMPARE(fixture.backend()->recentFolders().first(), folder);
}

void TestImageBrowserBackend::recentFolders_deduplicatesExistingEntry()
{
    TestFixture fixture;
    const QString folderA = fixture.createFolder(QStringLiteral("album-a"));
    const QString folderB = fixture.createFolder(QStringLiteral("album-b"));

    QCOMPARE(fixture.backend()->recentFolders().size(), 0);

    fixture.backend()->loadFolder(folderA);
    fixture.backend()->loadFolder(folderB);
    fixture.backend()->loadFolder(folderA);

    QCOMPARE(fixture.backend()->recentFolders().size(), 2);
    QCOMPARE(fixture.backend()->recentFolders().first(), folderA);
}

void TestImageBrowserBackend::recentFolders_keepsAtMostFiveEntries()
{
    TestFixture fixture;
    QStringList folders;
    for (int i = 0; i < 6; ++i) {
        folders << fixture.createFolder(QStringLiteral("album-%1").arg(i));
    }

    for (const QString &folder : folders) {
        fixture.backend()->loadFolder(folder);
    }

    QCOMPARE(fixture.backend()->recentFolders().size(), 5);
    QCOMPARE(fixture.backend()->recentFolders().first(), folders.last());
    QVERIFY(!fixture.backend()->recentFolders().contains(folders.first()));
}

void TestImageBrowserBackend::recentFolders_persistAcrossInstances()
{
    const QString settingsKey = QStringLiteral("recent_persist_%1").arg(QUuid::createUuid().toString());
    TestFixture fixture(settingsKey);
    const QString folder = fixture.createFolder(QStringLiteral("persisted"));
    fixture.backend()->loadFolder(folder);

    TestFixture fixture2(settingsKey, false);
    fixture2.backend()->loadFolder(fixture.createFolder(QStringLiteral("another")));

    QVERIFY(fixture2.backend()->recentFolders().contains(folder));
}

void TestImageBrowserBackend::exportFavorites_withNoFavorites_emitsInfoMessage()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("export-empty"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));

    QSignalSpy messageSpy(fixture.backend(), &ImageBrowserBackend::showMessage);
    fixture.backend()->loadFolder(folder);
    fixture.backend()->exportFavorites();

    QCOMPARE(messageSpy.count(), 1);
    QCOMPARE(messageSpy.at(0).at(1).toString(), QStringLiteral("info"));
}

void TestImageBrowserBackend::exportFavorites_copiesFilesToDestination()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("export-copy"));
    fixture.createImageFile(folder, QStringLiteral("fav1.jpg"), QByteArray("image-1"));
    fixture.createImageFile(folder, QStringLiteral("fav2.png"), QByteArray("image-2"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->toggleFavoriteForCurrent();
    fixture.backend()->setCurrentIndex(1);
    fixture.backend()->toggleFavoriteForCurrent();

    QSignalSpy messageSpy(fixture.backend(), &ImageBrowserBackend::showMessage);
    fixture.backend()->exportFavorites();

    QTRY_COMPARE_WITH_TIMEOUT(messageSpy.count(), 1, 5000);

    const QString destDir = fixture.rootPath()
            + QStringLiteral("/exports/")
            + QFileInfo(folder).fileName();
    QVERIFY(fixture.fileExists(destDir + QStringLiteral("/fav1.jpg")));
    QVERIFY(fixture.fileExists(destDir + QStringLiteral("/fav2.png")));
    QCOMPARE(messageSpy.at(0).at(0).toString().contains(QStringLiteral("2")), true);
}

void TestImageBrowserBackend::exportFavorites_skipsExistingDestinationFiles()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("export-skip"));
    const QString image = fixture.createImageFile(folder, QStringLiteral("fav.jpg"), QByteArray("source"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->toggleFavoriteForCurrent();

    const QString destDir = fixture.rootPath()
            + QStringLiteral("/exports/")
            + QFileInfo(folder).fileName();
    QDir().mkpath(destDir);
    fixture.createImageFile(destDir, QStringLiteral("fav.jpg"), QByteArray("existing"));

    QSignalSpy messageSpy(fixture.backend(), &ImageBrowserBackend::showMessage);
    fixture.backend()->exportFavorites();
    QTRY_COMPARE_WITH_TIMEOUT(messageSpy.count(), 1, 5000);

    QCOMPARE(fixture.readTextFile(destDir + QStringLiteral("/fav.jpg")), QStringLiteral("existing"));
    QCOMPARE(messageSpy.at(0).at(0).toString().contains(QStringLiteral("0")), true);
}

void TestImageBrowserBackend::exportFavorites_completesAsynchronously()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("export-async"));
    fixture.createImageFile(folder, QStringLiteral("async.jpg"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->toggleFavoriteForCurrent();

    QSignalSpy messageSpy(fixture.backend(), &ImageBrowserBackend::showMessage);
    fixture.backend()->exportFavorites();

    QVERIFY(messageSpy.isEmpty());
    QTRY_COMPARE_WITH_TIMEOUT(messageSpy.count(), 1, 5000);
}

void TestImageBrowserBackend::loadFolder_emitsStateChangeSignals()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("signals-load"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));

    ImageBrowserBackend *backend = fixture.backend();
    QSignalSpy imagePathsSpy(backend, &ImageBrowserBackend::imagePathsChanged);
    QSignalSpy totalCountSpy(backend, &ImageBrowserBackend::totalCountChanged);
    QSignalSpy favoriteCountSpy(backend, &ImageBrowserBackend::favoriteCountChanged);
    QSignalSpy currentPathSpy(backend, &ImageBrowserBackend::currentImagePathChanged);

    backend->loadFolder(folder);

    QCOMPARE(imagePathsSpy.count(), 1);
    QCOMPARE(totalCountSpy.count(), 1);
    QCOMPARE(favoriteCountSpy.count(), 1);
    QCOMPARE(currentPathSpy.count(), 1);
}

void TestImageBrowserBackend::setCurrentIndex_emitsCurrentIndexChanged()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("signals-index"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.createImageFile(folder, QStringLiteral("b.jpg"));

    fixture.backend()->loadFolder(folder);

    QSignalSpy indexSpy(fixture.backend(), &ImageBrowserBackend::currentIndexChanged);
    fixture.backend()->setCurrentIndex(1);
    QCOMPARE(indexSpy.count(), 1);
}

void TestImageBrowserBackend::loadFolder_emitsRecentFoldersChanged()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("signals-recent"));

    QSignalSpy recentSpy(fixture.backend(), &ImageBrowserBackend::recentFoldersChanged);
    fixture.backend()->loadFolder(folder);
    QCOMPARE(recentSpy.count(), 1);
    QVERIFY(fixture.backend()->recentFolders().contains(folder));
}

void TestImageBrowserBackend::toggleFavorite_emitsIsCurrentFavoriteChanged()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("signals-fav-state"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));

    fixture.backend()->loadFolder(folder);

    QSignalSpy favStateSpy(fixture.backend(), &ImageBrowserBackend::isCurrentFavoriteChanged);
    fixture.backend()->toggleFavoriteForCurrent();
    QCOMPARE(favStateSpy.count(), 1);
    QVERIFY(fixture.backend()->isCurrentFavorite());
}

void TestImageBrowserBackend::loadFolder_emitsCurrentIndexChanged()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("signals-index-load"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));

    QSignalSpy indexSpy(fixture.backend(), &ImageBrowserBackend::currentIndexChanged);
    fixture.backend()->loadFolder(folder);
    QCOMPARE(indexSpy.count(), 1);
    QCOMPARE(fixture.backend()->currentIndex(), 0);
}

void TestImageBrowserBackend::selectFolder_usesInjectedPicker()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("picker-target"));
    fixture.createImageFile(folder, QStringLiteral("picked.jpg"));

    fixture.backend()->setFolderPicker([folder]() { return folder; });
    fixture.backend()->selectFolder();

    QCOMPARE(fixture.backend()->totalCount(), 1);
    QVERIFY(fixture.backend()->currentImagePath().endsWith(QStringLiteral("picked.jpg")));
}

void TestImageBrowserBackend::selectFolder_emptyPickerResult_doesNothing()
{
    TestFixture fixture;
    fixture.backend()->setFolderPicker([]() { return QString(); });

    QSignalSpy messageSpy(fixture.backend(), &ImageBrowserBackend::showMessage);
    fixture.backend()->selectFolder();

    QCOMPARE(fixture.backend()->totalCount(), 0);
    QCOMPARE(messageSpy.count(), 0);
}

void TestImageBrowserBackend::favorites_multipleImages_trackedIndependently()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("multi-fav"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.createImageFile(folder, QStringLiteral("b.jpg"));
    fixture.createImageFile(folder, QStringLiteral("c.jpg"));

    fixture.backend()->loadFolder(folder);
    fixture.backend()->toggleFavoriteForCurrent();
    fixture.backend()->setCurrentIndex(2);
    fixture.backend()->toggleFavoriteForCurrent();

    QCOMPARE(fixture.backend()->favoriteCount(), 2);
    fixture.backend()->setCurrentIndex(1);
    QVERIFY(!fixture.backend()->isCurrentFavorite());
    fixture.backend()->setCurrentIndex(0);
    QVERIFY(fixture.backend()->isCurrentFavorite());
}

void TestImageBrowserBackend::favorites_isolatedPerFolder()
{
    TestFixture fixture;
    const QString folderA = fixture.createFolder(QStringLiteral("album-a"));
    const QString folderB = fixture.createFolder(QStringLiteral("album-b"));
    fixture.createImageFile(folderA, QStringLiteral("a.jpg"));
    fixture.createImageFile(folderB, QStringLiteral("b.jpg"));

    fixture.backend()->loadFolder(folderA);
    fixture.backend()->toggleFavoriteForCurrent();
    QCOMPARE(fixture.backend()->favoriteCount(), 1);

    fixture.backend()->loadFolder(folderB);
    QCOMPARE(fixture.backend()->favoriteCount(), 0);
    fixture.backend()->toggleFavoriteForCurrent();
    QCOMPARE(fixture.backend()->favoriteCount(), 1);

    fixture.backend()->loadFolder(folderA);
    QCOMPARE(fixture.backend()->favoriteCount(), 1);
    QVERIFY(fixture.backend()->isCurrentFavorite());
}

void TestImageBrowserBackend::exportFavorites_mkpathFailure_emitsMessage()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("export-blocked"));
    fixture.createImageFile(folder, QStringLiteral("fav.jpg"));

    const QString blocker = fixture.rootPath() + QStringLiteral("/blocked");
    QFile blockerFile(blocker);
    QVERIFY(blockerFile.open(QIODevice::WriteOnly));
    blockerFile.write("x");
    blockerFile.close();

    fixture.backend()->setExportDestRoot(blocker + QStringLiteral("/exports"));
    fixture.backend()->loadFolder(folder);
    fixture.backend()->toggleFavoriteForCurrent();

    QSignalSpy messageSpy(fixture.backend(), &ImageBrowserBackend::showMessage);
    fixture.backend()->exportFavorites();

    QCOMPARE(messageSpy.count(), 1);
    QVERIFY(messageSpy.at(0).at(0).toString().contains(QStringLiteral("无法创建目录")));
}

void TestImageBrowserBackend::workflow_loadNavigateFavoriteAndExport()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("workflow"));
    fixture.createImageFile(folder, QStringLiteral("01.jpg"), QByteArray("img-1"));
    fixture.createImageFile(folder, QStringLiteral("02.jpg"), QByteArray("img-2"));
    fixture.createImageFile(folder, QStringLiteral("03.jpg"), QByteArray("img-3"));

    ImageBrowserBackend *backend = fixture.backend();
    backend->loadFolder(folder);
    QCOMPARE(backend->totalCount(), 3);
    QCOMPARE(backend->currentIndex(), 0);

    backend->nextImage();
    backend->toggleFavoriteForCurrent();
    backend->nextImage();
    backend->toggleFavoriteForCurrent();
    QCOMPARE(backend->favoriteCount(), 2);

    QSignalSpy messageSpy(backend, &ImageBrowserBackend::showMessage);
    backend->exportFavorites();
    QTRY_COMPARE_WITH_TIMEOUT(messageSpy.count(), 1, 5000);

    const QString destDir = fixture.rootPath()
            + QStringLiteral("/exports/")
            + QFileInfo(folder).fileName();
    QVERIFY(fixture.fileExists(destDir + QStringLiteral("/02.jpg")));
    QVERIFY(fixture.fileExists(destDir + QStringLiteral("/03.jpg")));
    QVERIFY(!fixture.fileExists(destDir + QStringLiteral("/01.jpg")));

    backend->loadFolder(fixture.createFolder(QStringLiteral("other-album")));
    QCOMPARE(backend->totalCount(), 0);

    backend->loadFolder(folder);
    QCOMPARE(backend->favoriteCount(), 2);
    QVERIFY(backend->currentImagePath().endsWith(QStringLiteral("02.jpg"))
           || backend->currentImagePath().endsWith(QStringLiteral("03.jpg")));
}

QTEST_MAIN(TestImageBrowserBackend)
#include "tst_imagebrowserbackend.moc"
