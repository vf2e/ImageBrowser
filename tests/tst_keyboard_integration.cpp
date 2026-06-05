#include <QtTest>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QQuickItem>
#include <QDir>

#include "TestFixture.h"

class TestKeyboardIntegration : public QObject
{
    Q_OBJECT

private slots:
    void rightArrow_advancesIndex();
    void leftArrow_goesToPreviousIndex();
    void space_togglesFavorite();
    void unboundKey_doesNotChangeIndex();
};

static QString keyboardHarnessUrl()
{
    return QUrl::fromLocalFile(
        QDir(QString::fromUtf8(TEST_QML_DIR)).filePath(QStringLiteral("KeyboardHarness.qml"))).toString();
}

static QQuickWindow *loadHarnessWindow(QQmlApplicationEngine &engine, ImageBrowserBackend *backend)
{
    engine.rootContext()->setContextProperty(QStringLiteral("controller"), backend);
    engine.load(QUrl(keyboardHarnessUrl()));

    if (engine.rootObjects().isEmpty()) {
        return nullptr;
    }

    auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
    if (!window) {
        return nullptr;
    }

    window->show();
    if (!QTest::qWaitForWindowExposed(window)) {
        return nullptr;
    }

    if (auto *focusHost = window->property("focusHost").value<QQuickItem *>()) {
        focusHost->forceActiveFocus();
    }

    return window;
}

void TestKeyboardIntegration::rightArrow_advancesIndex()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("kb-nav"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.createImageFile(folder, QStringLiteral("b.jpg"));
    fixture.createImageFile(folder, QStringLiteral("c.jpg"));
    fixture.backend()->loadFolder(folder);
    QCOMPARE(fixture.backend()->currentIndex(), 0);

    QQmlApplicationEngine engine;
    QQuickWindow *window = loadHarnessWindow(engine, fixture.backend());
    QVERIFY(window != nullptr);

    QTest::keyClick(window, Qt::Key_Right);
    QCOMPARE(fixture.backend()->currentIndex(), 1);

    QTest::keyClick(window, Qt::Key_Right);
    QCOMPARE(fixture.backend()->currentIndex(), 2);
}

void TestKeyboardIntegration::leftArrow_goesToPreviousIndex()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("kb-left"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.createImageFile(folder, QStringLiteral("b.jpg"));
    fixture.backend()->loadFolder(folder);
    fixture.backend()->setCurrentIndex(1);

    QQmlApplicationEngine engine;
    QQuickWindow *window = loadHarnessWindow(engine, fixture.backend());
    QVERIFY(window != nullptr);

    QTest::keyClick(window, Qt::Key_Left);
    QCOMPARE(fixture.backend()->currentIndex(), 0);
}

void TestKeyboardIntegration::space_togglesFavorite()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("kb-fav"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.backend()->loadFolder(folder);
    QVERIFY(!fixture.backend()->isCurrentFavorite());

    QQmlApplicationEngine engine;
    QQuickWindow *window = loadHarnessWindow(engine, fixture.backend());
    QVERIFY(window != nullptr);

    QTest::keyClick(window, Qt::Key_Space);
    QVERIFY(fixture.backend()->isCurrentFavorite());

    QTest::keyClick(window, Qt::Key_Space);
    QVERIFY(!fixture.backend()->isCurrentFavorite());
}

void TestKeyboardIntegration::unboundKey_doesNotChangeIndex()
{
    TestFixture fixture;
    const QString folder = fixture.createFolder(QStringLiteral("kb-other"));
    fixture.createImageFile(folder, QStringLiteral("a.jpg"));
    fixture.createImageFile(folder, QStringLiteral("b.jpg"));
    fixture.backend()->loadFolder(folder);
    QCOMPARE(fixture.backend()->currentIndex(), 0);

    QQmlApplicationEngine engine;
    QQuickWindow *window = loadHarnessWindow(engine, fixture.backend());
    QVERIFY(window != nullptr);

    QTest::keyClick(window, Qt::Key_Tab);
    QCOMPARE(fixture.backend()->currentIndex(), 0);
}

QTEST_MAIN(TestKeyboardIntegration)
#include "tst_keyboard_integration.moc"
