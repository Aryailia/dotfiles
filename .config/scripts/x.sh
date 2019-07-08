#!/usr/bin/env sh

WALLPAPER="${HOME}/.config/wallpaper.png"

name="$( basename "$0"; printf a )"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name}

DESCRIPTION
  
EOF
}



# Handles single character-options joining (eg. pacman -Syu)
main() {
  # Flags

  # Dependencies

  # Options processing
  args=''
  no_options='false'
  while [ "$#" -gt 0 ]; do
    if ! "${no_options}"; then
      # Split grouped single-character arguments up, and interpret '--'
      # Parsing '--' here allows "invalid option -- '-'" error later
      opts=''
      case "$1" in
        --)      no_options='true'; shift 1; continue ;;
        -[!-]*)  opts="${opts}$( puts "${1#-}" | sed 's/./ -&/g' )" ;;
        *)       opts="${opts} $1" ;;
      esac

      # Process arguments properly now
      for x in ${opts}; do case "${x}" in
        -h|--help)  show_help; exit 0 ;;
        -e|--example)  puts "-$2-"; shift 1 ;;

        # Put argument checks above this line (for error detection)
        # first '--' case already covered by first case statement
        -[!-]*)   show_help; die 1 "FATAL: invalid option '${x#-}'" ;;
        *)        args="${args} $( puts "$1" | eval_escape )" ;;
      esac done
    else
      args="${args} $( puts "$1" | eval_escape )"
    fi
    shift 1
  done

  [ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"


  case "$1" in
    wall|setwall|set-wallpaper)  set_wallpaper "$@" ;;
    send|send-keys)  echo Send Keys WIP ;;
    *) echo WIP ;;
  esac

}

set_wallpaper() {
  [ -n "$1" ] && cp "$1" ~/.config/wallpapper.png \
    && notify-send -i "${WALLPAPER}" "Wallpaper set."
  xwallpaper --zoom "${WALLPAPER}"
}




# Helpers
puts() { printf %s\\n "$@"; }
puterr() { printf %s\\n "$@" >&2; }
die() { c="$1"; puterr "$2: '${name}' -- $3"; shift 3; puterr "$@"; exit "$c"; }

eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
