#!/usr/bin/env sh
  # Intended to be a portable clipboard interface

p() { printf '%s' "$@"; }
puts() { printf '%s\n' "$@"; }
has() { command -v "$1" >/dev/null; }

case "$1" in
  --write)
    content="$(</dev/stdin cat -)"
    has xclip && p "$content" | xclip -in -selection clipboard && exit 0
    ;;
  --read)
    has xclip && xclip -out -selection clipboard && exit 0
    ;;
  *)
    puts "$(basename "$0") <OPTION>"
    puts " --write   Copy STDIN to the clipboard"
    puts " --read    Copy from the clipboard to STDOUT"
esac

# Error out if none of the copies were successful
exit 1
