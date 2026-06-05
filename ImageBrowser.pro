QT += quick widgets concurrent

CONFIG += c++11

win32-msvc*: QMAKE_CXXFLAGS += /utf-8
win32-g++*: QMAKE_CXXFLAGS += -finput-charset=UTF-8 -fexec-charset=UTF-8

RC_ICONS = assets/icons/logo.ico

DEFINES += QT_DEPRECATED_WARNINGS

INCLUDEPATH += src/backend

SOURCES += \
        src/main.cpp \
        src/backend/ImageBrowserBackend.cpp

HEADERS += \
        src/backend/ImageBrowserBackend.h

RESOURCES += qml.qrc

QML_IMPORT_PATH =
QML_DESIGNER_IMPORT_PATH =

qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
