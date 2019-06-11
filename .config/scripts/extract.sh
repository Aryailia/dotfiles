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
  -c, --current-directory
     Extract archive into current directory rather than a new one.

  -i, --ignore-output-directory-existing
     Ignores the output directory already existing (check in case user already
     extracted the archive once, creating the directory)

  -l, --list-methods
     Prints out the current programs used in this script, just so you can
     reference if you want

  -o, --output-directory RELATIVEPATH
     Creates and extracts to the directory RELATIVEPATH
EOF
}

main() {
  # Options processing
  target=''; flag_ignore='false'
  args=''
  no_options='false'
  while [ "$#" -gt 0 ]; do
    "${no_options}" || case "$1" in
      --)  no_options='true'; shift 1; continue ;;
      -h|--help)  show_help; exit 1 ;;

      -c|--current-directory)  target='.' ;;
      -o|--output-directory)  target="$2"; shift 1 ;;
      -i|--ignore-output-directory-existing)  flag_ignore='true' ;;
      -l|--list-methods)  print_section >&2; exit 1 ;;

      *)   args="${args} $(puts "$1" | eval_escape)" ;;
    esac
    "${no_options}" && args="${args} $(puts "$1" | eval_escape)"
    shift 1
  done

  [ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"


  # Main
  for file in "$@"; do
    # Validation checks
    [ -f "${file}" ] || die2 1 'FATAL' "Archive '${file}' does not exist"

    # Need absolute path if doing `cd` later
    archive="$(realpath "${file}"; printf a)"; archive="${archive%?a}"
    base="$(basename "${archive}"; printf a)"; base="${base%?a}"
    if [ -z "${target}" ]
      then dir="${base%%.*}"
      else dir="${target}"
    fi

    # Ensure ${target} directory exists
    [ -d "${target}" ] && ! "${flag_ignore}" \
      die2 1 'FATAL' "Folder '${target}' already exists" \
        "Please specify a different folder with the -o option"
    mkdir -p "${target}" && cd "${dir}" \
      || die2 1 "FATAL" "Cannot make or cd to directory '${dir}'"

    case "${archive}" in
      # PRINT_START
      *.tar.bz2|*.tar.xz|*.tbz2)  tar xvjf "${archive}" ;;
      *.tar.gz|*.tgz)             tar xvzf "${archive}" ;;
      *.lzma)                     unlzma "${archive}" ;;
      *.bz2)                      bunzip2 "${archive}" ;;
      *.rar)                      unrar x -ad "${archive}" ;;
      *.gz)                       gunzip "${archive}" ;;
      *.tar)                      tar xvf "${archive}" ;;
      *.zip|*.xpi)                unzip "${archive}" ;;
      *.Z)                        uncompress "${archive}" ;;
      *.lz4|*.mozlz4|*.jsonlz4)   <"${archive}" mozlz4.py -d >"${base%.*}" ;;
      *.7z)                       7z x "${archive}" ;;
      *.xz)                       unxz "${archive}" ;;
      *.exe)                      cabextract "${archive}" ;;
      # PRINT_END
      *)  die2 1 'FATAL' \
        "'${archive}' -- '${archive##*.}' - unknown archive method" ;;
    esac
  done
}

print_section() {
  startkey='^ *# PRINT_START'
  endkey='^ *# PRINT_END'
  <"$0" sed "1,/${startkey}/d; /${endkey}/,\$d; s/^ *//"
}


# Helpers
puts() { printf %s\\n "$@"; }
die2() { c="$1"; t="$2"; shift 2; puts "$t: '${name}'" "$@" >&2; exit "$c"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
