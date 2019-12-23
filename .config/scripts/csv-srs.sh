#!/usr/bin/env sh

name="$( basename "$0"; printf a )"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name} <file> [<column> = 1]
  ${name} <file> [<column> = 1] --all [--start <num>]
  ${name} <file> [<column> = 1] --start <num>
  ${name} --help

DESCRIPTION
  Presents the <column>-th column of a random row from the csv file '<file>'
  to the user, then prints the rest of the columns on individual rows.

  SRS comes from Spaced-Repetition Software like Anki.  Note, this just does
  plain randomisation so it's not actually an SRS.

OPTIONS
  -a, --all
    Print every line.  Randomizes each time a pass is completed.

  -h, --help
    Prints this help menu.

  -s, --start <row-number>
    Skip the lines from <file> before <row-number>
EOF
}



main() {
  # Flags
  STARDICT_DIR="${STARDICT_DATA_DIR}/zh"
  RANDOMLY='true'
  START_AT='1'

  # Dependencies
  require 'xsv' || die 1 FATAL "\`xsv\` not installed"
  require 'shuf' || die 1 FATAL "\`shuf\` not installed"
  require 'sed' || die 1 FATAL "\`sed\` not installed"

  # Options processing
  args=''; literal='false'
  # TODO: Specify which dictionary to main options
  while [ "$#" -gt 0 ]; do
    "${literal}" || case "$1" in
      --)  literal='true'; shift 1; continue ;;
      -h|--help)   show_help; exit 0 ;;
      -a|--all)    RANDOMLY='false' ;;
      -s|--start)  START_AT="${2}"; shift 1 ;;
      *)   args="${args} $( outln "$1" | eval_escape )" ;;
    esac
    "${literal}" && args="${args} $( outln "$1" | eval_escape )"
    shift 1
  done
  for arg in "$@"; do
    "${literal}" || case "${arg}" in
      --)  literal='true' ;;
      *)   args="${args} $( outln "${arg}" | eval_escape )" ;;
    esac
    "${literal}" && args="${args} $( outln "${arg}" | eval_escape )"
  done

  [ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"

  # More checks
  [ -r "${1}" ] || die 1 FATAL "Input file '${1}' not readable"

  if "${RANDOMLY}"; then
    file="${1}"
  else
    # Randomise the input
    require 'mktemp' || die 1 FATAL "\`mktemp\` not installed"
    file="$( mktemp )"
    <"${1}" sed -n "${START_AT},\$p" | shuf >"${file}"
    trap 'rm -f "${file}"; outln; exit' EXIT INT
  fi

  total_lines="$( <"${file}" wc -l )"
  [ "${total_lines}" -ge 2 ] || die 1 FATAL 'Less than 2 lines'



  # Main
  input=""
  column="${2:-1}"
  row="0"
  while [ "${input}" != "q" ] && [ "${input}" != 'Q' ]; do
    # Calculate ${row}
    if "${RANDOMLY}"; then
      # Randomly get one line
      # Adds a number line to all lines
      # -p no-renumber, -s separator, -w number-width, -b body-numbering
      #   -b a: number the blank lines
      #   -p: not actually sure how `nl` handles sections
      #   -w 1: remove the paddings
      #   -s '|': add a pipe after
      # -e expression, -n head-count
      # filters out non-blank lines, then grabs a random line
      row="$( <"${file}" \
        nl -p -s '|' -w 1 -b a \
        | sed -e '/^[0-9]*|[ \t]*$/d' -e '/^[0-9]*|[ \t]*\/\//d' \
          -e "${START_AT},\$p" \
        | shuf -n 1 \
        | xsv select --delimiter '|' 1 )"
    else
      row="$(( row + 1 ))"
      while sed -n "${row}p" "${file}" | grep -q '^[ \t]*$'; do
        row="$(( row + 1 ))"
      done

      # Finished, so repeat
      if [ "${row}" -gt "${total_lines}" ]; then
        <"${1}" sed -n "${START_AT},\$p" | shuf >"${file}"
        row="1"
        while sed -n "${row}p" "${file}" | grep -q '^[ \t]*$'; do
          row="$(( row + 1 ))"
        done
      fi
    fi
    history_push "${row}"

    # Print the head and options for editing, etc.
    display_and_menu "${file}" "${row}" "${column}" || exit "$?"

    # Print the answer
    # `sed` and `trim_every_line` to remove extras added by `xsv`
    history_current_line "${file}" \
      | xsv select --no-headers --delimiter '|' "!${column}" \
      | xsv flatten --no-headers \
      | sed 's/^[0-9]*//' \
      | trim_every_line
  done
}

MENU="########  (a/c/d/e/h/l/n/p/q/) 'h' for help, '' for next ########"
display_current_head() {
  outln "${MENU}"
  out "$( history_current_line "${1}" \
    | xsv select --delimiter '|' "${2}" \
    | trim_every_line
  )" " "
}
display_and_menu() {
  display_current_head "${1}" "${3}"
  while : ; do
    case "$( prompt '.*' "" )" in
      h*) outln \
        "  'h' for help" \
        "  'a' to repeat the entry" \
        "  'c' to edit the current entry in \${EDITOR} '${EDITOR}'" \
        "  'd' to lookup in the dictionary" \
        "  'e' to edit the previous entry in \${EDITOR} '${EDITOR}'" \
        "  'l' to lookup in the dictionary" \
        "  'n' to go forward in history" \
        "  'p' to go backward in history" \
        "  'q' to quit" \
        "  ''  to reveal the answer and next entry" \
        ;;
      a*) outln "Again"; display_current_head "${1}" "${3}" ;;
      c*) out "Edited "
        "${EDITOR:-vim}" "+normal! $( history_current )G" "${1}" ;;
      d*) sdcv --data-dir "${STARDICT_DIR}" "${3}"
        out "Dictionary " ;;
      e*) out "Edited "; "${EDITOR:-vim}" "+normal! ${PREVIOUS:-1}G" "${1}" ;;
      l*) outln "Use Ctrl-D to return"
        sdcv --data-dir "${STARDICT_DIR}"
        out "Dictionary back " ;;
      n*) PREVIOUS="$( history_current )"
        history_forward
        display_current_head "${1}" "${3}"
        outln "" "$(( $( out "${HISTORY_FORWARD}" | wc -l ) - 1 )) in front" ;;
      p*) PREVIOUS="$( history_current )"
        history_backward
        display_current_head "${1}" "${3}"
        outln "" "$(( $( out "${HISTORY_FORWARD}" | wc -l ) - 1 )) in front" ;;
      q*) return 1 ;;
      *) break ;;
    esac
  done
  PREVIOUS="${2}"
  return 0
}

################################################################################
# History
LN='
'
HISTORY_LENGTH="30"       # Negative number for unlimited
HISTORY_BACKWARD="${LN}"  # "\n1\n2\n" preceeded and succeeded by newline
HISTORY_FORWARD="1${LN}"  # suceeded but not preceeded (see `history_get`)
history_backward() {
  if [ -n "${HISTORY_BACKWARD#${LN}}" ]; then
    HISTORY_BACKWARD="${HISTORY_BACKWARD%${LN}}"
    HISTORY_FORWARD="${HISTORY_BACKWARD##*${LN}}${LN}${HISTORY_FORWARD}"
    HISTORY_BACKWARD="${HISTORY_BACKWARD%${LN}*}${LN}"
  fi
}
history_forward() {
  if [ -n "${HISTORY_FORWARD#*${LN}}" ]; then  # Need at least one entry
    HISTORY_BACKWARD="${HISTORY_BACKWARD}${HISTORY_FORWARD%%${LN}*}${LN}"
    HISTORY_FORWARD="${HISTORY_FORWARD#*${LN}}"
  fi
}

history_push() {
  HISTORY_BACKWARD="${HISTORY_BACKWARD}${HISTORY_FORWARD%%${LN}*}${LN}"
  if [ "${HISTORY_LENGTH}" -ge 0 ] && \
     [ "$( outln "${HISTORY_BACKWARD}" | wc -l )" -gt "${HISTORY_LENGTH}" ]
     # ${HISTORY_BACKWARD} has an extra line so use -gt
  then
    HISTORY_BACKWARD="${LN}${HISTORY_BACKWARD#${LN}*${LN}}"
  fi
  HISTORY_FORWARD="${1}${LN}"
}
# Not padding both sides of ${HISTORY_FORWARD} with newline so this is easier
history_current() { out "${HISTORY_FORWARD%%${LN}*}"; }
history_current_line() { sed -n "$( history_current )p" "${1}"; }



################################################################################
# Helpers
trim_every_line() { sed -e 's/^ *//' -e 's/ *$//'; }

prompt() {
  [ -n "${2}" ] && errln "${2}"
  read -r value
  while outln "${value}" | grep -qve "${1}"; do
    [ -n "${3:-"${2}"}" ] && errln "${3:-"${2}"}"
    read -r value
  done
  printf %s "${value}"
}

out() { printf %s "$@"; }
outln() { printf %s\\n "$@"; }
errln() { printf %s\\n "$@" >&2; }
die() { c="$1"; errln "$2: '${name}' -- $3"; shift 3; errln "$@"; exit "$c"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

require() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0
  done
  return 1
}

main "$@"
