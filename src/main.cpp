#include <QApplication>
#include <QFont>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTextCodec>
#include "ImageBrowserBackend.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication app(argc, argv);

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QTextCodec::setCodecForLocale(QTextCodec::codecForName("UTF-8"));
#endif

    QFont appFont(QStringLiteral("Microsoft YaHei"));
    appFont.setStyleStrategy(QFont::PreferAntialias);
    app.setFont(appFont);

    QQmlApplicationEngine engine;

    auto *backend = new ImageBrowserBackend(&app);
    engine.rootContext()->setContextProperty("backend", backend);

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
