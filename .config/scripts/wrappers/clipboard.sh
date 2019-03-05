#!/usr/bin/env sh
  # >/dev/stdin $0 <type> <?content1> <?content2> ...
# Intended to be a portable clipboard interface

show_help_and_exit() {
  name="$(basename "$0"; printf x)"; name="${name%??}"
  <<EOF cat - >&2
SYNOPSIS
  [<STDIN] ${name} OPTIONS [INPUTS ...]

DESCRIPTION
  Wrapper for the clipboard across different environments

OPTIONS
  --h, --help
    Display this help

  -r, --read
    Copy from the clipboard to STDOUT

  -w, --write INPUTS <STDIN
    Copy either STDIN or <inputs> to the clipboard
    Specifying <inputs> will ignore STDIN


EXAMPLES
  \$ ${name} --write 'hello' 'world'       # helloworld
  \$ echo 'hello world' | ${name} --write  # hello world\n
  \$ ${name} --read
  \$ ${name} --help
EOF
}



# Helpers
prints() { printf '%s' "$@"; }
puts() { printf '%s\n' "$@"; }
has() { command -v "$1" >/dev/null 2>&1; }



# Parameters
option="$1"
[ "$#" -gt 0 ] && shift 1

# Main
case "$option" in
  -h|--help)  show_help; exit 0 ;;

  -w|--write)
    content="$(if [ "$#" -eq 0 ]
      then <&0 cat -
      else prints "$@"
    fi)"

    has xclip \
      && { prints "${content}" | xclip -in -selection clipboard; } \
      && exit 0
    has termux-clipboard-set \
      && { prints "${content}" | termux-clipboard-set; } \
      && exit 0
    ;;

  -r|--read)
    has xclip && xclip -out -selection clipboard && exit 0
    has termux-clipboard-get && termux-clipboard-get && exit 0
    ;;

  *)  show_help; exit 1 ;;
esac

echo 'ERROR: Cannot find clipboard program'
exit 1
