QT += quick widgets concurrent

CONFIG += c++11

msvc: QMAKE_CXXFLAGS += /utf-8

RC_ICONS = assets/icons/logo.ico

DEFINES += QT_DEPRECATED_WARNINGS

SOURCES += \
        main.cpp \
        ImageBrowserBackend.cpp

HEADERS += \
        ImageBrowserBackend.h

RESOURCES += qml.qrc
QML_IMPORT_PATH =

QML_DESIGNER_IMPORT_PATH =

qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
