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

ENUM_DEFAULT='0'
ENUM_TEMPDIR='1'
#ENUM_SPECIFY='2'
OUTPUT="${ENUM_DEFAULT}"

main() {
  # Options processing
  args=''; literal='false'
  for arg in "$@"; do
    "${literal}" || case "${arg}" in
      --)  literal='true' ;;
      -h|--help)  show_help; exit 0 ;;
      -t|--temp)  OUTPUT="${ENUM_TEMPDIR}" ;;
      *)   args="${args} $( soutln "${arg}" | eval_escape )" ;;
    esac
    "${literal}" && args="${args} $( soutln "${arg}" | eval_escape )"
  done

  [ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"

  for pathname in "$@"; do
    dir=""
    case "${OUTPUT}" in
      "${ENUM_DEFAULT}")  dir="$( dirname "${pathname}"; printf a )"
                          dir="${dir%?a}" ;;
      "${ENUM_TEMPDIR}")  dir="${TMPDIR}" ;;
      #"${ENUM_SPECIFY}")  "" ;;
    esac
    target="${pathname##*/}"
    target="${dir}/${target%.*}"
    case "${target}" in
      /*)  target="/.${target}" ;;
      *)   target="./${target}" ;;  # Chance for '//' but whatever
    esac

    case "${pathname##*.}" in
      tex)                      process_latex "${pathname}" "${target}" ;;
      ad|adoc|asciidoctor|asc)  process_adoc "${pathname}" "${target}" ;;
    esac
  done
}


# First argument is path to source file
# Second argument is path minus its extension with unique ././ or /./ prepended
process_latex() {
  cmd="$( if sed 5q "$1" | grep -iq 'xelatex'
    then printf pdflatex
    else printf xelatex
  fi )"
  dir="${2%/*}"
  "${cmd}" --output-directory="${dir}" "$1" \
    && grep -i addbibresource "$1" >/dev/null \
    && biber --input-directory "${dir}" "$1" \
    && "${cmd}" --output-directory="${dir}" "$1" \
    && "${cmd}" --output-directory="${dir}" "$1"
  soutln "$2.pdf"
}

process_adoc() {
  asciidoctor "$1" --backend html5 --destination-dir "${2%/*}"
  soutln "$2.html"
}

process_adoc_pdf() {
  asciidoctor-pdf -r asciidoctor-pdf-cjk-kai_gen_gothic \
    -a pdf-style=KaiGenGothicCN \
    -o "$2.pdf" "$1"
  soutln "$2.pdf"
}

soutln() { printf %s\\n "$@"; }
serrln() { printf %s\\n "$@" >&2; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
die() { c="$1"; serrln "$2: '${name}' -- $3"; shift 3; serrln "$@"; exit "$c"; }

main "$@"