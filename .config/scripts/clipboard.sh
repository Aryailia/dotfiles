#!/usr/bin/env sh
  # Intended to be a portable clipboard interface

option="$1"
[ "$#" -gt 0 ] && shift 1

p() { printf '%s' "$@"; }
puts() { printf '%s\n' "$@"; }
has() { command -v "$1" >/dev/null; }

case "$option" in
  --write)
    content="$(if [ "$#" -eq 0 ]
      then <&0 cat -
      else p "$@"
    fi)"
    has xclip && p "${content}" | xclip -in -selection clipboard && exit 0
    ;;
  --read)
    has xclip && xclip -out -selection clipboard && exit 0
    ;;
  *)
    name="$(basename "$0")" 
    puts "${name} <OPTION> [<inputs>]"
    puts " --write   Copy either STDIN or <inputs> to the clipboard"
    puts "           Specifying <inputs> will ignore STDIN"
    puts " --read    Copy from the clipboard to STDOUT"
    puts ""
    puts "Examples"
    puts "========"
    puts "\$ ${name} --write 'hello' 'world'       # helloworld"
    puts "\$ echo 'hello world' | ${name} --write  # hello world\n"
    puts "\$ ${name} --read"
    puts "\$ ${name} --help"
esac

# Error out if none of the copies or reads were successful
exit 1
