#include <QtQuickTest>
#include <QObject>

class QmlTestSetup : public QObject
{
    Q_OBJECT
public:
    QmlTestSetup()
    {
        const QByteArray paths = QByteArray(QML_IMPORT_ROOT) + ';' + QByteArray(QT_QML_IMPORT_PATH);
        qputenv("QML2_IMPORT_PATH", paths);
        qputenv("QT_PLUGIN_PATH", QT_PLUGIN_PATH);
        qputenv("QT_QPA_PLATFORM", "offscreen");
    }
};

QUICK_TEST_MAIN_WITH_SETUP(tst_qml, QmlTestSetup)

#include "tst_qml.moc"
