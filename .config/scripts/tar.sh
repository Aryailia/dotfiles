#!/usr/bin/env sh

[ -r "$1" ] || { echo "$1 file not found"; exit 1; }

case "$1" in
  *.xz)
    tar --xz -xzf "$1" 
    ;;
esac
