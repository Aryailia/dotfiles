#!/usr/bin/env sh
  # >/dev/stdin $0 <type> <?content1> <?content2> ...
# Intended to be a portable clipboard interface

# Parameters
option="$1"
[ "$#" -gt 0 ] && shift 1

show_help() {
  name="$(basename "$0")" 
  puts "SYNOPSIS"
  puts "  ${name} OPTIONS"
  puts ""
  puts "DESCRIPTION"
  puts "  Wrapper for the clipboard across different environments"
  puts ""
  puts "OPTIONS"
  puts "  --h, --help"
  puts "    Display this help"
  puts ""
  puts "  -r, --read"
  puts "    Copy from the clipboard to STDOUT"
  puts ""
  puts "  -w, --write INPUTS <STDIN"
  puts "    Copy either STDIN or <inputs> to the clipboard"
  puts "    Specifying <inputs> will ignore STDIN"
  puts ""
  puts ""
  puts "EXAMPLES"
  puts "  \$ ${name} --write 'hello' 'world'       # helloworld"
  puts "  \$ echo 'hello world' | ${name} --write  # hello world\n"
  puts "  \$ ${name} --read"
  puts "  \$ ${name} --help"
}



# Helpers
p() { printf '%s' "$@"; }
puts() { printf '%s\n' "$@"; }
has() { command -v "$1" >/dev/null 2>&1; }



# Main
case "$option" in
  -h|--help)  show_help; exit 0;;

  -w|--write)
    content="$(if [ "$#" -eq 0 ]
      then <&0 cat -
      else p "$@"
    fi)"
    has xclip && { p "${content}" | xclip -in -selection clipboard; } && exit 0
    echo ''
    echo 'asdfklkjasdf'
    echo ''
    has termux-clipboard-set \
      && { p "${content}" | termux-clipboard-set; } \
      && exit 0
  ;;

  -r|--read)
    has xclip && xclip -out -selection clipboard && exit 0
    has termux-clipboard-get && termux-clipboard-get && exit 0
  ;;

  *)  show_help; exit 1;;
esac

echo 'ERROR: Cannot find clipboard program'
exit 1
