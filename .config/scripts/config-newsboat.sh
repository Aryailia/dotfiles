#!/usr/bin/env sh

NAME="$( basename "$0"; printf a )"; NAME="${NAME%?a}"

show_help() {
  <<EOF cat - >&2
USAGE
  ${NAME} <OPTION>

DESCRIPTION
  A better way to specify (update the config with -m flag) and display the
  macro list (-l flag). Newsboat does not provide an in-program method to
  display the available macros.

OPTIONS
  -h, --help
    Show this help menu

  -l, --list
    List the macros available with fzf, notify, or direct STDOUT automatically
    determined at runtime

  -m, --make
    Edit the config "${NEWSBOAT_CONFIG}" with these macros

  -t, --tags
    Copies to clipboard what the current start and close tags are (useful
    if we change them in future, can just paste into the file)
EOF
}

# 'show-urls' pipes
# 'open-in-browser' provides %u
DEFAULT_VIEWER='uriscan -lms - | handle.sh'
DEFAULT_BROWSER='handle.sh t -l'
NEWSBOAT_CONFIG="${XDG_CONFIG_HOME}/newsboat/config"
NEWSBOAT_CONFIG_L="\${XDG_CONFIG_HOME}/newsboat/config"

main() {
  #run: sh % -m
  m_link  h 'display marco list'     "${NAME} --list"
  m_link  t 'display/notify link'    "notify.sh '%u'"
  m_pipe  T 'display/notify entry'   "notify.sh -"
  # These wrap around? Honestly forgot why i have these
  m_input n "next feed's unread"     "next-feed article-list ; next-unread"
  m_input p "previous feed's unread" "prev-feed article-list ; prev-unread"

  m_link  v 'download video'         "queue.sh youtube-dl --video"
  m_link  a 'download audio only'    "queue.sh youtube-dl --audio"
  m_link  s 'download subbed video'  "queue.sh youtube-dl --video --subtitles"
  m_link  c 'download copy link'     "clipboard.sh --write '%u'"
  m_pipe  C 'download copy link'     "uriscan.sh -lms - | clipboard.sh -w -"
  # Symmetry: Regular keybind 'o' opens in terminal
  m_link  o 'gui open link'          "handle.sh g -l '%u'"
  m_pipe  O 'link menu open in gui'  "uriscan.sh -lms - | handle.sh g -l -i"

  m_pipe  e 'entry in term editor'   "\${EDITOR}"
  m_pipe  d 'link menu download'     "uriscan.sh -lms - | handle.sh d -l -i"
  # use "sh -c" to eat first argument that newsboat automatically gives (%u)
  m_link  E 'edit newsboat config'   "sh -c '\${EDITOR} ${NEWSBOAT_CONFIG_L}'"
  m_info  E 'edit newsboat urls'

  OUT="# Default macro key is ,
# 'external-url-viewer' pipes to command
# 'browser' provides %u or provides it as first argument
external-url-viewer \"${DEFAULT_VIEWER}\"
browser \"${DEFAULT_BROWSER}\"

${OUT}"

  # Options processing
  for arg in "$@"; do
    case "${arg}"
      in -h|--help) show_help
      #;; -o) out "${OUT}"
      ;; -l|--list) menu '' #menu "display"  # non-empty ${1} for direct display
      ;; -m|--make) in_file_replace "${NEWSBOAT_CONFIG}" "${OUT}"
      ;; -t|--tags)
        errln "Copy to clipboard"
        clipboard.sh --write "${START_TAG}${NL}${CLOSE_TAG}${NL}"
      ;; *) errln "Invalid argument '${arg}'"; show_help; exit 1  # Error exit
    ;; esac
    exit 0  # We always exit
  done
  [ "$#" = 0 ] && { show_help; exit 1; }

}

ENUM_LINK='0'
ENUM_PIPE='1'
ENUM_INPUT='2'
ENUM_INFO='3'
#CTRL="^"
NL='
'

menu() {
  if [ -n "$1" ]; then
    display 123
  elif echo | fzf --select-1 >/dev/null; then
    display 123 | fzf --prompt="Macro Help List> " --reverse
  elif [ -n "${DISPLAY}" ]; then
    display 12 | notify.sh -
  else
    display 123
    printf %s\\n "Press 'enter' to exit> "
    IFS= read -r null
  fi
}

START_TAG="######## start ~ automatically replaced by '${NAME}' ########"
CLOSE_TAG="######## close ~ automatically replaced by '${NAME}' ########"

in_file_replace() {
  # $1: filename
  # $2: items to replace
  [ -f "$1" ] || die FATAL 1 "File '$1' does not exist; "

  _replacer="util-replace.sh"
  require "${_replacer}" || die FATAL 1 "Could not find  '${_replacer}'"
  _replacement="$(
    <"${1}" "${_replacer}" "${START_TAG}" "${2}" "${CLOSE_TAG}"
    _e="$?"
    printf a
    return "${_e}"
  )" || die FATAL 1
  _replacement="${_replacement%a}"

  printf %s "${_replacement}" >"$1"
}

################################################################################
DISPLAY_COL1="KEY${NL}"
DISPLAY_COL2="DESCRIPTION${NL}"
DISPLAY_COL3="COMMAND${NL}"
OUT=''

display() {
  # allow
  len1="$( outln "${DISPLAY_COL1}" | get_max_width )"
  len2="$( outln "${DISPLAY_COL2}" | get_max_width )"
  bool1="false"
  bool2="false"
  bool3="false"
  [ "${1}" != "${1#*1}" ] && bool1="true"
  [ "${1}" != "${1#*2}" ] && bool2="true"
  [ "${1}" != "${1#*3}" ] && bool3="true"

  outln "'*' before key means this is a regular keybind"
  outln
  while [ -n "${DISPLAY_COL1}" ]; do
    col1="${DISPLAY_COL1%%${NL}*}"
    col2="${DISPLAY_COL2%%${NL}*}"
    col3="${DISPLAY_COL3%%${NL}*}"
    DISPLAY_COL1="${DISPLAY_COL1#${col1}${NL}}"  # guarenteed to have \n
    DISPLAY_COL2="${DISPLAY_COL2#${col2}${NL}}"  # guarenteed to have \n
    DISPLAY_COL3="${DISPLAY_COL3#${col3}${NL}}"  # guarenteed to have \n
    "${bool1}" && printf "%-${len1}s" "${col1}"
    "${bool1}" && "${bool2}" && printf " | "
    "${bool2}" && printf "%-${len2}s" "${col2}"
    "${bool3}" && { "${bool1}" || "${bool2}"; } && printf " | "
    "${bool3}" && printf "%s" "${col3}"
    printf \\n
  done
}

get_max_width() {
  __len='0'
  while IFS= read -r line; do
    [ "${#line}" -gt "${__len}" ] && __len="${#line}"
  done
  out "${__len}"
}

################################################################################
# 'm' for macro, save characters
m_link() {  register_macro "${ENUM_LINK}" "$@"; }
m_pipe() {  register_macro "${ENUM_PIPE}" "$@"; }
m_input() { register_macro "${ENUM_INPUT}" "$@"; }
m_info() {  register_macro "${ENUM_INFO}" "*${1}" "${2}" 'invalid'; }

register_macro() {
  # $1: ENUM
  # $2: Key
  # $3: Description
  # $4: Command
  [ -n "${2}" ] || die DEV 1 "Empty key" "At: $*"
  [ -n "${3}" ] || die DEV 1 "Empty description" "At: $*"
  [ -n "${4}" ] || die DEV 1 "Empty command" "At: $*"

  # More validation
  [ "${4}" != "${4#*\"}" ] && die DEV 1 \
    "Probably best if newsboat macros do not have double quotes" "At: $*"
  [ "${DISPLAY_COL1}" != "${DISPLAY_COL1#*"${NL}${2}${NL}"}" ] && die DEV 1 \
    "Macro for '$2' is already defined" "At: $*"


  DISPLAY_COL1="${DISPLAY_COL1}${2}${NL}"
  DISPLAY_COL2="${DISPLAY_COL2}${3}${NL}"
  DISPLAY_COL3="${DISPLAY_COL3}${4}${NL}"


  if   [ "${1}" = "${ENUM_LINK}" ]; then
    # The ';' next to "${4}" seems to be important for newsboat
    OUT="${OUT}macro ${2} set browser \"${4}\"; open-in-browser ; "
    OUT="${OUT}set browser \"${DEFAULT_BROWSER}\"${NL}"
  elif [ "${1}" = "${ENUM_PIPE}" ]; then
    # The ';' next to "${4}" seems to be important for newsboat
    OUT="${OUT}macro ${2} set external-url-viewer \"${4}\"; show-urls ; "
    OUT="${OUT}set external-url-viewer \"${DEFAULT_VIEWER}\"${NL}"
  elif [ "${1}" = "${ENUM_INPUT}" ]; then
    OUT="${OUT}macro ${2} ${4}${NL}"
  elif [ "${1}" = "${ENUM_INFO}" ]; then
    :  # do not add to "${OUT}"
  else
    die DEV 1 "Invalid enum in source code"
  fi

}


# Helpers
out() { printf %s "$@"; }
outln() { printf %s\\n "$@"; }
errln() { printf %s\\n "$@" >&2; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }
require() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0
  done
  return 1
}

main "$@"
