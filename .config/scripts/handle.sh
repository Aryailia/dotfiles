#!/usr/bin/env sh

name="$( basename "$0"; printf a )"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name}

DESCRIPTION
  
OPTIONS
  --
    Special
EOF
}

# ANSI color codes are supported.
# STDIN is disabled, so interactive scripts won't work properly
# This script is considered a configuration file and must be updated manually.

# Meanings of exit codes:
# code | meaning    | action of lf
# -----+------------+-------------------------------------------
# 0    | success    | Display stdout as preview
# 1    | no preview | Display no preview at all
# 2    | plain text | Display the plain content of the file

# Settings
HIGHLIGHT_SIZE_MAX=262143  # 256KiB
HIGHLIGHT_TABWIDTH=8
HIGHLIGHT_STYLE='pablo'
#PYGMENTIZE_STYLE='autumn'

# Enums
FLAG_PRINT='false'
ENUM_DEFAULT='0'
ENUM_SUCCESS='0'
ENUM_NOPREVIEW='1'  # Or error, or make ENUM_ERROR?
ENUM_PLAINTEXT='2'

PATH_TYPE="${ENUM_DEFAULT}"
ENUM_HYPERTEXT='1'
ENUM_FILE='2'

ENUM_DOWNLOAD='1'
ENUM_TERMINAL='2'
ENUM_GUI='3'
ENUM_PREVIEW='4'
ENUM_EDIT='5'
COMMAND="${ENUM_TERMINAL}"  # Select the default


# Handles options that need arguments
main() {
  # Dependencies

  # Options processing
  args=''
  no_options='false'
  while [ "$#" -gt 0 ]; do
    "${no_options}" || case "$1" in
      --)  no_options='true'; shift 1; continue ;;
      -h|--help)  show_help; exit 0 ;;
      -p|--print)     FLAG_PRINT='true' ;;
      -l|--link)      PATH_TYPE="${ENUM_HYPERTEXT}" ;;
      -f|--file)      PATH_TYPE="${ENUM_FILE}" ;;

      -d|--download)  COMMAND="${ENUM_DOWNLOAD}" ;;
      -t|--terminal)  COMMAND="${ENUM_TERMINAL}" ;;
      -g|--gui)       COMMAND="${ENUM_GUI}" ;;
      -v|--preview)   COMMAND="${ENUM_PREVIEW}" ;;
      -e|--edit)      COMMAND="${ENUM_EDIT}" ;;

      *)   args="${args} $( puts "$1" | eval_escape )" ;;
    esac
    "${no_options}" && args="${args} $( puts "$1" | eval_escape )"
    shift 1
  done

  eval "set -- ${args}"
  # if NOT ${ENUM_EDIT}, then -C no overwite files with output redirection '>'
  [ "${COMMAND}" != "${ENUM_EDIT}" ] && set -C

  # Cannot download local files
  # Cannot edit online files
  # Careful about boolean operator order
  if  [ "${PATH_TYPE}" = "${ENUM_FILE}" ] || {
      [ "${PATH_TYPE}" = "${ENUM_DEFAULT}" ] && [ -e "${1}" ] \
    ; }
  then
    [ "${COMMAND}" = "${ENUM_DOWNLOAD}" ] \
      && die "${ENUM_NOPREVIEW}" 'FATAL' 'Cannot `--download` local paths'

    local_handle_extension "${1}"
    local_handle_mime "${1}"
    local_handle_fallback "${1}"
    exit "${ENUM_NOPREVIEW}"
  else
    [ "${COMMAND}" = "${ENUM_EDIT}" ] \
      && die "${ENUM_NOPREVIEW}" 'FATAL' 'Cannot `--edit` hypertext links'
    external_handle_link "${1}"
  fi
}

# TODO: check BROWSER run
external_handle_link() {
  #echo link >&2
  case "${1}" in
    *youtube.com/watch*|*youtu.be*|*clips.twitch.tv*|*bitchute.com*|*hooktube*)
      d queue.sh youtube-dl --video "${1}"; d exit "${ENUM_SUCCESS}"
      require 'mpv' && { t mpv --vo=caca --quiet -- "${1}"
        exit "${ENUM_SUCCESS}"; }
      c.sh is-android || { g setsid mpv --quiet -- "$1" >/dev/null 2>&1&
        exit "${ENUM_SUCCESS}"; }
      ;;

    *huya.com/*|*twitch.tv*)
      g streamlink -- "${1}" '320p,480p,worst'
      ;;

    *.gif|*.png|*.bmp|*.tiff|*.jpeg|*.jpe|*.jpg)
      g curl -L "${1}" | sxiv -ai && exit "${ENUM}"
      ;;

    *.ogg|*.flac|*.opus|*.mp3|*.m4a|*.aac)
      require 'mpv' && { t mpv --quiet "${1}"; exit "${ENUM_SUCCESS}"; }
      require 'mpv' && { g setsid mpv --quiet "${1}" >/dev/null 2>&1
        exit "${ENUM_SUCCESS}"; }
      ;;
    *reddit.com*)
      require 'tuir' && { t tuir "${1}"; exit "${ENUM_SUCCESS}"; } ;;
  esac

  d queue.sh direct "${1}"
  t browser.sh run "${BROWSER_CLI}" -- "${1}"
  g browser.sh run "${BROWSER}" -- "${1}"
  p echo WIP
  exit "${ENUM_SUCCESS}"
}

local_handle_extension() {
  #echo local >&2
  lowercase_extension="$( puts "${1##*.}" | tr '[:upper:]' '[:lower:]' )"
  case "${lowercase_extension}" in
    a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|\
    rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)
      p atool --list -- "${1}"
      p bsdtar --list --file "${1}"
      exit "${ENUM_NOPREVIEW}" ;;
    rar)
      # Avoid password prompt by providing empty password
      p unrar lt -p- -- "${1}"
      exit "${ENUM_NOPREVIEW}" ;;
    7z)
      # Avoid password prompt by providing empty password
      p 7z l -p -- "${1}"
      exit "${ENUM_NOPREVIEW}" ;;

    # PDF
    pdf)
      # Preview as text conversion
      t sh -c "pdftotext -nopgbrk -q -- '${1}' - | '${EDITOR}'"
      t exit "${ENUM_SUCCESS}"
      g setsid zathura -- "${1}" >/dev/null 2>&1& g exit "${ENUM_SUCCESS}"
      #e sigil
      p pdftotext -l 10 -nopgbrk -q -- "${1}" -  # -l lines, -q quiet
      #p mutool draw -F txt -i -- "${1}" 1-10
      p exiftool "${1}"
      exit "${ENUM_NOPREVIEW}" ;;

    ## BitTorrent
    #torrent)
    #  transmission-show -- "${1}"
    #  exit "${ENUM_NOPREVIEW}" ;;

    ## OpenDocument
    #odt|ods|odp|sxw)
    #  p odt2txt "${1}"
    #  exit "${ENUM_NOPREVIEW}" ;;

    doc|docx|xls|xlsx)
      g setsid libreoffice "${1}"
      exit "${ENUM_NOPREVIEW}" ;;

    # HTML
    htm|html|xhtml)
      p w3m -dump "${1}"
      p lynx -dump -- "${1}"
      p elinks -dump "${1}"
      ;; # Continue with next handler

    1)  man ./ "${uri}" | col -b ;;
  esac
}

local_handle_mime() {
  mimetype="$( file --dereference --brief --mime-type -- "${1}" )"
  case "${mimetype}" in
    # Text
    text/* | */xml)
      # Syntax highlight
      if [ "$( stat --printf='%s' -- "${1}" )" -gt "${HIGHLIGHT_SIZE_MAX}" ]
        then exit "${ENUM_PLAINTEXT}"
      fi
      if [ "$( tput colors )" -ge 256 ]; then
        pygmentize_format='terminal256'
        highlight_format='xterm256'
      else
        pygmentize_format='terminal'
        highlight_format='ansi'
      fi
      t "${EDITOR}" "${2}"
      g "${TERMINAL}" -e "${EDITOR}" "${2}"
      #c.sh is-android || g "${TERMINAL}" -e "${EDITOR}" "${2}"
      #c.sh is-android && g "${TERMINAL}" -e "${EDITOR}" "${2}"
      p highlight --replace-tabs="${HIGHLIGHT_TABWIDTH}" \
        --out-format="${highlight_format}" \
        --style="${HIGHLIGHT_STYLE}" --force -- "${1}"
      #p pygmentize -f "${pygmentize_format}" -O "style=${PYGMENTIZE_STYLE}" \
      #   -- "${1}"
      exit "${ENUM_PLAINTEXT}" ;;

    # Image
    image/*)
      #t ueberzug "${1}" && exit "${ENUM_SUCCESS}"
      g setsid sxiv -a "${1}" >/dev/null 2>&1& g exit "${ENUM_SUCCESS}"
      e setsid krita -- "${1}" >/dev/null 2>&1& e exit "${ENUM_SUCCESS}"
      #p img2txt --gamma=0.6 -- "${1}" && exit "${ENUM_SUCCESS}"
      p exiftool "${1}"
      exit "${ENUM_NOPREVIEW}" ;;

    # Video and audio
    video/* | audio/*|application/octet-stream)
      #p mediainfo "${1}"
      g mpv "${1}"
      p exiftool "${1}"
      exit "${ENUM_NOPREVIEW}" ;;

  esac

}

local_handle_fallback() {
  p puts '----- File Type Classification -----' \
    && p file --dereference --brief -- "${FILE_PATH}"
  exit "${ENUM_NOPREVIEW}"
}



# Adding true at the end to protect and short-circuit if statements
printrun() { if "${FLAG_PRINT}"; then printf '%s ' "$@"; else "$@"; fi; true; }
d() { [ "${COMMAND}" = "${ENUM_DOWNLOAD}" ] && printrun "$@"; }
t() { [ "${COMMAND}" = "${ENUM_TERMINAL}" ] && printrun "$@"; }
g() { [ "${COMMAND}" = "${ENUM_GUI}" ] && printrun "$@"; }
p() { [ "${COMMAND}" = "${ENUM_PREVIEW}" ] && printrun "$@"; }
e() { [ "${COMMAND}" = "${ENUM_EDIT}" ] && printrun "$@"; }



# Helpers
require() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0
  done
  return 1
}
puts() { printf %s\\n "$@"; }
puterr() { printf %s\\n "$@" >&2; }
die() { c="$1"; puterr "$2: '${name}' -- $3"; shift 3; puterr "$@"; exit "$c"; }

eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
