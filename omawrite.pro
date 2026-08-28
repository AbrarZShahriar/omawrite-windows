QT += core gui widgets printsupport qml quick quickcontrols2 quickdialogs2

unix: QT += dbus
win32: QT += svg

CONFIG += c++17 release
TARGET = omawrite
TEMPLATE = app

VERSION = 0.5.0
QMAKE_TARGET_PRODUCT = OmaWrite
QMAKE_TARGET_DESCRIPTION = OmaWrite Markdown editor
QMAKE_TARGET_COPYRIGHT = Copyright (c) OmaWrite contributors

HEADERS += \
    src/backend.h \
    src/markdownhighlighter.h \
    src/systemtheme.h

SOURCES += \
    src/main.cpp \
    src/backend.cpp \
    src/markdownhighlighter.cpp \
    src/systemtheme.cpp

RESOURCES += src/resources.qrc

win32: RC_ICONS = pkgbuild/omawrite.ico
