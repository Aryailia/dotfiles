#!/usr/bin/env sh

name="$( basename "$0"; printf a )"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name}

DESCRIPTION
  

OPTIONS
  --
    Special argument that prevents all following arguments from being
    intepreted as options.
EOF
}


RED='\001\033[31m\002'
GREEN='\001\033[32m\002'
YELLOW='\001\033[33m\002'
BLUE='\001\033[34m\002'
MAGENTA='\001\033[35m\002'
CYAN='\001\033[36m\002'
CLEAR='\001\033[0m\002'

main() {
  [ "$#" = 0 ] && eval "set -- $( prompt '.*' "$( outln \
    "${CYAN}pinyin${CLEAR}" \
    "${CYAN}example${CLEAR} <arg> [<arg2>]" \
    "${CYAN}example2${CLEAR} <dir> <arg2> ..." \
    "Enter one of the options: ${CYAN}" \
  )" )"
  cmd="${1}"; shift 1
  case "${cmd}" in
    h*)  show_help; exit 0 ;;

    p*)  pinyin "$@" ;;
    2)   echo 2 ;;

    *)   show_help; exit 1 ;;
  esac
}


#run:% p 你好
pinyin() {
  # Check if 

  # Run pinyin on the input
  program="$(<<"  EOF" cat
    const pinyin = require('pinyin');
    process.argv.slice(2).forEach(function (arg) {
      console.log(
        arg.split('').map(function (c) {
          return pinyin(c, {
            style:     pinyin.STYLE_TONE,
            heteronym: true,
            segment:   false,
          })[0].join("/")
        }).join("")
      )
    })
  EOF
  )"
  outln "${program}" | node - "$@"
}


# Helpers
pc() { printf %b "$@" >/dev/tty; }
prompt() {
  pc "${2}"; read -r value; pc "${CLEAR}"
  while outln "${value}" | grep -qve "$1"; do
    pc "${3:-"$2"}"; read -r value
    pc "${CLEAR}"
  done
  printf %s "${value}"
}

outln() { printf %s\\n "$@"; }
errln() { printf %s\\n "$@" >&2; }
die() { c="$1"; errln "$2: '${name}' -- $3"; shift 3; errln "$@"; exit "$c"; }

eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
