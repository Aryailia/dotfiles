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

  for sourcepath in "$@"; do
    dir=""
    case "${OUTPUT}" in
      "${ENUM_DEFAULT}")  dir="$( dirname "${sourcepath}"; printf a )"
                          dir="${dir%?a}" ;;
      "${ENUM_TEMPDIR}")  dir="${TMPDIR}" ;;
      #"${ENUM_SPECIFY}")  "" ;;
    esac
    target="${sourcepath##*/}"
    target="${dir}/${target%.*}"
    case "${target}" in
      /*)  target="/.${target}" ;;
      *)   target="./${target}" ;;  # Chance for '//' but whatever
    esac

    case "${sourcepath##*.}"
      in tex)          process_latex "${sourcepath}" "${target}"
      #;; tex)          process_latex_with_tectonic "${sourcepath}" "${target}"
      ;; ad|adoc|asc)  process_adoc "${sourcepath}" "${target}"
      ;; asciidoctor)  process_adoc "${sourcepath}" "${target}"
      ;; md)           process_cmark "${sourcepath}" "${target}"

    esac
  done
}

process_cmark() {
  <"$1" awk '
    NR == 1 && $0 == "---" { frontmatter = 1; }
    NR != 1 && $0 == "---" { frontmatter = 0; next; }
    frontmatter == 1 { next; }
    { print $0; }
  ' | comrak --unsafe --output "$2.html"
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

process_latex_with_tectonic() {
  tectonic "$1" --outdir "${2%/*}"
}

process_adoc() {
  imagesdir="$( <"${1}" sed -n '/^:imagesdir:/{s/^:.*: *//p}' )"
  dir="$( realpath "${1}"; printf a )"; dir="${dir%?a}"
  dir="$( dirname "${dir}"; printf a )"; dir="${dir%?a}"
  target="$( realpath "${dir}/${imagesdir}"; printf a )"; target="${target%?a}"
  #bibtex="$( gem list --local | grep '^asciidoctor-bibtex ' )" || exit "$?"
  bibtex=''
  if [ -n "${bibtex}" ]
    then bibtex="--require=asciidoctor-bibtex"
    else bibtex=""
  fi

  # '-a webfonts!' disables <link> to fonts.googleapis.com
  asciidoctor "${1}" --backend html5 --destination-dir "${2%/*}" \
    ${bibtex} \
    --attribute source-highlighter='pygments' \
    --attribute 'webfonts!' \
    --attribute imagesdir="${target}" \
  #
  soutln "${2}.html"
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
