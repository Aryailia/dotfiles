#!/usr/bin/env sh

NAME="$( basename "$0"; printf a )"; NAME="${NAME%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${NAME} <SUBCOMMAND> <URI>

DESCRIPTION
  Inspired from Ranger's 'scope.sh', basically a terminal form of xdg-open
  but we can open terminal programs

  ANSI color codes are supported.
  STDIN is disabled, so interactive scripts won't work properly
  This script is considered a configuration file and must be updated manually.

  Meanings of exit codes:
  code | meaning    | action of lf
  -----+------------+-------------------------------------------
  0    | success    | Display stdout as preview
  1    | no preview | Display no preview at all
  2    | plain text | Display the plain content of the file


SUBCOMMANDS
  download
  terminal
  gui
  preview
  edit

OPTIONS
  --
    Special
EOF
}

# Customisation
BAT_THEME="Solarized (light)"

# Enums
FLAG_PRINT='false'
ENUM_DEFAULT='0'

CODE_STDOUT='0'
CODE_NOPREVIEW='1'  # Or error, or make ENUM_ERROR?
CODE_PLAINTEXT='2'

PATH_TYPE="${ENUM_DEFAULT}"
ENUM_HYPERTEXT='1'
ENUM_FILE='2'

# No default
CMD_DOWNLOAD='1'
CMD_TERMINAL='2'
CMD_GUI='3'
CMD_PREVIEW='4'
CMD_EDIT='5'
COMMAND="${ENUM_TERMINAL}"  # Select the default

main() {
  #TODO: maybe want terminal viewers set read-only where relevant?
  #TODO: disable interactive scripts by disabling STDOUT? See ranger's scope.sh
  # Guard against overwriting files with output redirection '>'
  set -C

  # Options processing
  args=''; literal='false'
  while [ "$#" -gt 0 ]; do
    "${literal}" || case "${1}"
      in --)  no_options='true'; shift 1; continue
      ;; -h|--help)   show_help; exit "${CODE_STDOUT}"
      ;; -p|--print)  FLAG_PRINT='true'
      ;; -l|--link)   PATH_TYPE="${ENUM_HYPERTEXT}"
      ;; -f|--file)   PATH_TYPE="${ENUM_FILE}"
      ;; -i|--stdin)  args="${args} $( <&0 eval_escape )"
      ;; -*)  die FATAL 1 "No option '${1}' suppoorted"
      ;; *)   args="${args} $( outln "${1}" | eval_escape )"
    esac
    "${literal}" && args="${args} $( outln "${1}" | eval_escape )"
    shift 1
  done

  eval "set -- ${args}"

  case "${1}"
    in d*)  COMMAND="${CMD_DOWNLOAD}"
    ;; t*)  COMMAND="${CMD_TERMINAL}"
    ;; g*)  COMMAND="${CMD_GUI}"
    ;; p*)  COMMAND="${CMD_PREVIEW}"
    ;; e*)  COMMAND="${CMD_EDIT}"
    ;; *)   die FATAL "${CODE_NOPREVIEW}" "invalid subcommand" '`'"$*"'`'
  esac

  [ "$#" != 2 ] && die FATAL 1 \
    "Must open just one link. Try '-i' if piping" "$@"

  # Cannot download local files
  # Cannot edit online files
  # Careful about boolean operator order
  if  [ "${PATH_TYPE}" = "${ENUM_FILE}" ] \
    || { [ "${PATH_TYPE}" = "${ENUM_DEFAULT}" ] && [ -e "${2}" ]; }
  then
    d_do die FATAL "${CODE_NOPREVIEW}" "Cannot 'download' local paths"
    HANDLE_TYPE='extension' handle_extension "${2}"
    HANDLE_TYPE='mime' local_handle_mime "${2}"
    HANDLE_TYPE='fallback' local_handle_fallback "${2}"
    die FATAL "${CODE_NOPREVIEW}" "No program found"
  else
    e_do die FATAL "${CODE_NOPREVIEW}" "Cannot 'edit' hypertext links"
    HANDLE_TYPE='link' handle_link "${2}"
  fi
}


# TODO: check BROWSER run
# `t ...`, `g ...`, etc. propagate their conditions so can `&& exit ...`
handle_link() {
  #echo link >&2
  case "${1}"
    in *youtube.com/watch*|*youtu.be*)
      d        "${CODE_NOPREVIEW}" queue.sh youtube-dl --video -- "${1}"
      t        "${CODE_NOPREVIEW}" mpv --vo=caca --quiet -- "${1}"
      ! c.sh is-android && g_launch "${CODE_NOPREVIEW}" mpv --quiet -- "${1}"

    ;; *clips.twitch.tv*|*bitchute.com*|*hooktube*)
      t        "${CODE_NOPREVIEW}" mpv --vo=caca --quiet -- "${1}"
      ! c.sh is-android && g_launch "${CODE_NOPREVIEW}" mpv --quiet -- "${1}"

    ;; *huya.com/*|*twitch.tv*)
      g_launch "${CODE_NOPREVIEW}" streamlink -- "${1}" '320p,480p,worst'

    ;; *.gif|*.png|*.bmp|*.tiff|*.jpeg|*.jpe|*.jpg)
      t        "${CODE_NOPREVIEW}" sh -c 'curl -L -- "${1}" | chafa -' _ "${1}"

      # sxiv needs to read a file so have to `mktemp`
      g_launch "${CODE_NOPREVIEW}" sh -c '
        image="$( mktemp )" || {
          printf %s\\n "Cannot make a temp file" >&2
          exit 1
        }
        trap "rm -f \"${image}\"" EXIT
        curl -Lo "${image}" -- "${1}"
        printf %s\\n "Opening ${image}" >&2
        sxiv -a "${image}"  # -a for play animations
      ' _ "${1}"

    ;; *.ogg|*.flac|*.opus|*.mp3|*.m4a|*.aac)
      req 'mpv' && t        "${CODE_NOPREVIEW}" mpv --quiet "${1}"
      req 'mpv' && g_launch "${CODE_NOPREVIEW}" \
        "${TERMINAL}" -e mpv --quiet "${1}"

    ;; *reddit.com*)
      t        "${CODE_NOPREVIEW}" tuir "${1}"

    ;;
  esac

  # Fallbacks
  d        "${CODE_NOPREVIEW}" queue.sh direct "${1}"
  t        "${CODE_NOPREVIEW}" browser.sh terminal link "${1}"
  g_launch "${CODE_NOPREVIEW}" browser.sh gui link "${1}"
  exit_message 'link, but program not found' "${CODE_NOPREVIEW}"
}

#TODO think about to proceed with fallbacks or not (i.e. the early exit's)
handle_extension() {
  #echo local >&2
  lowercase_extension="$( outln "${1##*.}" | tr '[:upper:]' '[:lower:]' )"
  case "${lowercase_extension}"
    in a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|\
       rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)
      p "${CODE_STDOUT}" atool --list -- "${1}"
      exit_message 'extension' "${CODE_NOPREVIEW}"  # do not fallback

    ;; rar)
      # Avoid password prompt by providing empty password
      p "${CODE_STDOUT}" unrar lt -p- -- "${1}"
      exit_message 'extension' "${CODE_NOPREVIEW}"  # do not fallback

    ;; 7z)
      # Avoid password prompt by providing empty password
      p "${CODE_STDOUT}" 7z l -p -- "${1}"
      exit_message 'extension' "${CODE_NOPREVIEW}"  # do not fallback

    ;; epub)
      g_launch "${CODE_NOPREVIEW}" zathura -- "${1}"
      p        "${CODE_STDOUT}" exiftool "${1}"

    ;; pdf)
      # Preview as text conversion
      t        "${CODE_NOPREVIEW}" \
        sh -c 'pdftotext -nopgbrk -q -- "${1}" - | "${EDITOR}"' _ "${1}"
      g_launch "${CODE_NOPREVIEW}" zathura -- "${1}"
      #e        "${CODE_NOPREVIEW}" sigil

      # pdftotext is too slow for my tastes
      # -l lines, -q quiet
      #p        "${CODE_STDOUT}" pdftotext -l 2 -nopgbrk -q -- "${1}" -
      #p        "${CODE_STDOUT}" mutool draw -F txt -i -- "${1}" 1-10
      p        "${CODE_STDOUT}" exiftool "${1}"

    ## BitTorrent
    #;; torrent)
    #  transmission-show -- "${1}"
    #  exit "${CODE_NOPREVIEW}"

    ## OpenDocument
    #;; odt|ods|odp|sxw)
    # p "${CODE_STDOUT}" odt2txt "${1}"
    #  exit "${CODE_NOPREVIEW}"

    ;; doc|docx|xls|xlsx|ppt|pptx|ods)
      g_launch "${CODE_NOPREVIEW}" libreoffice "${1}"

    # HTML
    ;; htm|html|xhtml)
      t        "${CODE_NOPREVIEW}" browser.sh terminal link "${1}"
      g_launch "${CODE_NOPREVIEW}" browser.sh gui link "${1}"

      req 'w3m'    && p "${CODE_STDOUT}" w3m -dump "${1}"
      req 'lynx'   && p "${CODE_STDOUT}" lynx -dump -- "${1}"
      req 'elinks' && p "${CODE_STDOUT}" elinks -dump "${1}"

    ;; 1)  man ./ "${1}" | col -b
    ;;
  esac
}

# NOTE: Unquoted spaces in pattern match of case-structure are skipped
#       so `text/* | *xml)` is the same as `text/*|*xml)`
local_handle_mime() {
  mimetype="$( file --dereference --brief --mime-type -- "${1}" )"
  case "${mimetype}"
    # Text
    in text/* | */xml)
      # Syntax highlight
      t        "${CODE_STDOUT}"     "${EDITOR}" "${1}"
      ! c.sh is-android && g_launch \
               "${CODE_NOPREVIEW}"  "${TERMINAL}" -e "${EDITOR}" "${1}"
      c.sh is-android && g \
               "${CODE_NOPREVIEW}"  "${EDITOR}" "${1}"
      p        "${CODE_STDOUT}"     \
        bat --color always --line-range '40:' --pager never -- "${1}"
      #exit_message 'mime' "${CODE_PLAINTEXT}"  # Do not fallback

    # Image
    ;; image/*)
      #t        "${CODE_NOPREVIEW}" ueberzug "${1}"
      t        "${CODE_NOPREVIEW}" chafa -- "${1}"
      g_launch "${CODE_NOPREVIEW}" sxiv -a -- "${1}"
      e_launch "${CODE_NOPREVIEW}" krita -- "${1}"
      #p       "${CODE_STDOUT}"    img2txt --gamma=0.6 -- "${1}"
      #p       "${CODE_STDOUT}"       \
      #  chafa --colors 16 --symbols=vhalf --bg="#000000" --"${1}"
      p        "${CODE_STDOUT}"    exiftool -- "${1}"

    # Video and audio
    ;; video/* | audio/* | application/octet-stream)
      t        "${CODE_NOPREVIEW}" mpv "${1}"
      g        "${CODE_NOPREVIEW}" mpv "${1}"
      p        "${CODE_NOPREVIEW}" exiftool "${1}"
      #p        "${CODE_NOPREVIEW}" mediainfo "${1}"
      # TODO: thumbnail preview

    ;;
  esac

}

local_handle_fallback() {
  p "${CODE_STDOUT}" outln '----- File Type Classification -----' \
    "$( file --dereference --brief -- "${FILE_PATH}" )"
}



################################################################################
# Adding true at the end to protect and short-circuit if statements
print_or_run() {
  error_code="${1}"
  shift 1
  if "${FLAG_PRINT}"; then
    err "${HANDLE_TYPE}: "; escape_all "$@"
  else
    errln "Opening/Launching ${HANDLE_TYPE}" "$*"
    "$@"
  fi
  exit "${error_code}"
}

print_or_launch() {
  error_code="${1}"
  shift 1
  if "${FLAG_PRINT}"; then
    err "${HANDLE_TYPE}: "; escape_all "$@"
  else
    errln "Opening/Launching ${HANDLE_TYPE} (may take a while)..." "$*"
    setsid "$@" & #>/dev/null 2>&1&
  fi
  exit "${error_code}"
}

e_launch() { e_do print_or_launch "$@"; }
g_launch() { g_do print_or_launch "$@"; }
d() { d_do print_or_run "$@"; }
t() { t_do print_or_run "$@"; }
g() { g_do print_or_run "$@"; }
p() { p_do print_or_run "$@"; }
e() { e_do print_or_run "$@"; }


d_do() { [ "${COMMAND}" = "${CMD_DOWNLOAD}" ] && "$@"; }
t_do() { echo "$COMMAND"; [ "${COMMAND}" = "${CMD_TERMINAL}" ] && "$@"; }
g_do() { [ "${COMMAND}" = "${CMD_GUI}" ] && "$@"; }
p_do() { [ "${COMMAND}" = "${CMD_PREVIEW}" ] && "$@"; }
e_do() { [ "${COMMAND}" = "${CMD_EDIT}" ] && "$@"; }

# Helpers
out() { printf %s "$@"; }
outln() { printf %s\\n "$@"; }
err() { printf %s "$@" >&2; }
errln() { printf %s\\n "$@" >&2; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }

exit_message() {
  errln "Opening/Launching ${1}"
  exit "$(( ${2} - 1 ))"
}

eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
escape_all() {
  [ "$#" = 0 ] && return 1
  outln "${1}" | eval_escape
  shift 1
  for arg in "$@"; do outln "${arg}" | eval_escape; done
  outln ''
}
req() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/${1}" ] && [ -x "${dir}/${1}" ] && return 0
  done
  return 1
}

main "$@"
