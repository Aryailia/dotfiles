#!/usr/bin/env sh
# I have always thought global constants marked implicitly (defined in
# 'bash_profile') just screams bad programming practice, are hard to follow.
# Having a script that one must calls for constants makes it explicitly a
# global constant and makes it easier to find.

p() { printf '%s' "$@"; }

case "$1" in
  -h|--help)  puts "Outputs constants. I think this adds transparency." ;;
  cdpath)             p "${HOME}/.config/named_directories" ;;
  dl|downloads)       android_downloads="/sdcard/Downloads"
                      if [ -d "${android_downloads}" ]
                        then p "${android_downloads}"
                        else p "${HOME}/Downloads"
                      fi ;;
  dq|download-queue)  p "${TMPDIR}/download_queue" ;;
  env|environment)    p "${HOME}/.environment" ;;  # aka .env/
  scihub)             p 'http://sci-hub.tw' ;;  # changes frequently
  *) exit 1;;
esac
