#!/usr/bin/env sh
# I have always thought global constants marked implicitly (defined in
# 'bash_profile') just screams bad programming practice, are hard to follow.
# Having a script that one must calls for constants makes it explicitly a
# global constant and makes it easier to find.

p() { printf '%s' "$@"; }

case "$1" in
  -h|--help)  puts "Outputs constants. I think this adds transparency." ;;
  cdpath)             p "${HOME}/.config/named_directories" ;;
  dl|downloads)       android_downloads="/sdcard/Download"
                      if [ -d "${android_downloads}" ]
                        then p "${android_downloads}"
                        else p "${HOME}/Downloads"
                      fi ;;
  dq|download-queue)  p "${TMPDIR}/download_queue" ;;
  env|environment)    p "${HOME}/.environment" ;;  # aka .env/
  scihub)             p 'http://sci-hub.tw' ;;  # changes frequently
  # https://stackoverflow.com/questions/19306771/
  current-user)       ps -o user= "$$" | awk '{ printf("%s", $1); }' ;;

  # Also check '.profile', will never use `c.sh` in '.profile'
  # Yes that means duplicate code
  #is-macos)           uname -o | grep -q 'Linux' ;;
  is-linux)           uname -o | grep -q 'Linux' ;;
  is-windows)         uname -o | grep -q 'MSYS' ;;
  is-android)         uname -o | grep -q 'Android' ;;
  *) exit 1;;
esac
