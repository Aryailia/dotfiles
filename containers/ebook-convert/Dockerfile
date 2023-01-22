# calibre updated to python3 as of version 5.0
# python2 -> python3 represents a break in backwards compatability
# Calibre 5.0 first starts being packaged in ubuntu:20.04
FROM ubuntu:latest

# https://www.mobileread.com/forums/showthread.php?t=348820
# https://doc.qt.io/qt-6/qtwebengine-debugging.html
# https://github.com/linuxserver/docker-calibre/blob/master/Dockerfile


# The following are what calibre specifies are the build requirements
# We need libnss3 for ebook-convert
RUN apt-get update \
  && apt-get install -y libnss3 wget libegl1 libopengl0 python3 xz-utils xdg-utils \
  && rm -rf /var/lib/apt/lists/* \
  && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | /bin/sh -
# done

# mkdir fresh dir for hosting
RUN mkdir /root/opt
# done

COPY --chmod=500 convert.sh /root/convert.sh

WORKDIR /root/
