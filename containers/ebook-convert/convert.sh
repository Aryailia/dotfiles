#!/bin/sh
# https://doc.qt.io/qt-6/qtwebengine-debugging.html

#https://www.mobileread.com/forums/showthread.php?t=348820

wd="/root/opt"

# Using container root in podman will create files with the sameuid and gid host user
# ebook-convert(calibre) uses qt chromium to render files
# QT chromium needs --nos-sandbox passed to it to run as root
# The container root also has the benefit less code to deal with permissions
QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox" ebook-convert "${wd}/${1}" "${wd}/${2}"
