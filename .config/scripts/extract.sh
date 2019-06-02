#!/usr/bin/env sh

name="$(basename "$0"; printf a)"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name} [OPTIONS]

DESCRIPTION
  A general, all-purpose extraction script.
  Default behavior, extracts archive into new directory

OPTIONS
  -c, --curent-directory
     Extract archive into current directory rather than a new one.
EOF
}


main() {
  # Options processing
  archive=''
  args=""; no_options='false'
  for arg in "$@"; do "${no_options}" || case "${arg}" in
    --)  no_options='true' ;;
    -h|--help)  show_help; exit 0 ;;

    -c|--current-directory)
      archive="$(readlink -f "$*"; printf a)"; archive="${archive%?a}"
      target="$(basename "${archive}"; printf a)"; target="${target%?a}"
      mkdir -p "${target}"
      cd "${target}" || exit
      ;;

    *)  args="${args} $(puts "${arg}" | eval_escape)"
  esac done

  eval "set -- ${args}"
  [ -z "$*" ] && { puts "Need archive to extract" >&2; show_help; exit 1; }
  [ -z "${archive}" ] && archive="$(readlink -f "$(puts "$*" | cut -d' ' -f2)")"


  # Main
  if [ -f "${archive}" ] ; then
    case "${archive}" in
      *.tar.bz2|*.tar.xz|*.tbz2)  tar xvjf "${archive}" ;;
      *.tar.gz|*.tgz)             tar xvzf "${archive}" ;;
      *.lzma)                     unlzma "${archive}" ;;
      *.bz2)                      bunzip2 "${archive}" ;;
      *.rar)                      unrar x -ad "${archive}" ;;
      *.gz)                       gunzip "${archive}" ;;
      *.tar)                      tar xvf "${archive}" ;;
      *.zip)                      unzip "${archive}" ;;
      *.Z)                        uncompress "${archive}" ;;
      *.7z)                       7z x "${archive}" ;;
      *.xz)                       unxz "${archive}" ;;
      *.exe)                      cabextract "${archive}" ;;
      *)  printf 'extract: "%s" - unknown archive method\n' "${archive}" ;;
    esac
  else
    printf 'File "%s" not found.\n' "${archive}"
  fi
}



# Helpers
puts() { printf %s\\n "$@"; }
die2() { c="$1"; t="$2"; shift 2; puts "$t: '${name}'" "$@" >&2; exit "$c"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
#!/bin/sh

