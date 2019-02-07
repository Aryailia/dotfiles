#!/usr/bin/env sh
# I have always thought global constants marked implicitly (defined in
# 'bash_profile') just screams bad programming practice, are hard to follow.
# Having a script that one must calls for constants makes it explicitly a
# global constant and makes it easier to find.

p() { printf '%s' "$@"; }

case "$1" in
  downloads)      p "${HOME}/storage/downloads/queue";;
  download-queue) p "${TMPDIR}/download_queue";;
  environment) p "${HOME}/.environment";; # aka .env/
  scihub)      p 'http://sci-hub.tw';; # changes frequently
  shortcuts)   p "${HOME}/.config/named_directories";; # aka CDPATH
  *) exit 1;;
esac
