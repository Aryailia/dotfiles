#!/usr/bin/env sh

[ -e "${TMPDIR}" ] || { printf %s\\n "\${TMPDIR} not specified"; exit 1; }
cd "/tmp" || exit 1
file="broadcom-wl-5.100.138"
if [ -e "${file}" ]; then
  curl -LO "http://www.lwfinger.com/b43-firmware/${file}.tar.bz2"
  tar xjf "${file}.tar.bz2"
fi
export FIRMWARE_INSTALL_DIR="/usr/lib/firemware"
sudo b43-fwcutter -w "${FIRMWARE_INSTALL_DIR}" "${file}/linux/wl_apsta.o"
