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

################################################################################
# Options and main logic
main() {
  # Flags
  STARDICT_DIR="${STARDICT_DATA_DIR}/zh"
  RANDOMLY='true'
  STDIN='false'
  START_AT='1'
  END_AT='$'

  # Dependencies
  require 'xsv' || die 1 FATAL "\`xsv\` not installed"
  require 'shuf' || die 1 FATAL "\`shuf\` not installed"
  require 'sed' || die 1 FATAL "\`sed\` not installed"
  require 'mktemp' || die 1 FATAL "\`mktemp\` not installed"

  # Options processing
  args=''; literal='false'
  # TODO: Specify which dictionary to main options
  while [ "$#" -gt 0 ]; do
    "${literal}" || case "$1" in
      --)  literal='true'; shift 1; continue ;;
      -)   STDIN='true' ;;
      -h|--help)   show_help; exit 0 ;;
      -a|--all)    RANDOMLY='false' ;;
      -s|--start)  START_AT="${2}"; shift 1 ;;
      -e|--end)    END_AT="${2}"; shift 1 ;;
      *)   args="${args} $( outln "$1" | eval_escape )" ;;
    esac
    "${literal}" && args="${args} $( outln "$1" | eval_escape )"
    shift 1
  done

  [ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"

  # ${1} maps to ${INPUT}
  # ${2} maps to ${column}

  # Setup the ${INPUT} and ${FILE} files
  # Capitalise ${INPUT} and ${FILE} because are globals and used by `trap`
  FILE="$( mktemp )"
  if "${STDIN}"
    then INPUT="$( mktemp )"; cat - >"${INPUT}"
    else INPUT="${1}"
  fi
  trap 'rm -f "${FILE}"; "${STDIN}" && rm -f "${INPUT}"; outln; exit' EXIT INT

  ##############################################################################
  # Main logic
  [ -r "${INPUT}" ] || die 1 FATAL "Input file '${INPUT}' not readable"
  <"${INPUT}" initial_transform >"${FILE}"

  # Main
  total_lines="$( <"${FILE}" wc -l )"
  [ "${total_lines}" -ge 2 ] || die 1 FATAL 'Need at least 2 lines'

  # Main
  column="${2:-1}"
  column_plus_one="$(( column + 1 ))"
  row="0"
  REMIND=""
  while :; do
    # Calculate ${row}
    if "${RANDOMLY}"; then
      row="$( <"${FILE}" shuf -n 1 | row_from_line )"
    else
      row="$(( row + 1 ))"

      # Finished, so repeat
      # TODO: Add an echo to indicate finished
      if [ "${row}" -gt "${total_lines}" ]; then
        outln "" "## Starting over ##" ""
        <"${INPUT}" initial_transform >"${FILE}"
        row="1"
      fi
    fi
    history_push "${row}"

    # Print the head and options for editing, etc.
    # Overwrites "${FILE} (second argument) whenever user makes an edit
    display_and_menu "${INPUT}" "${FILE}" "${row}" "${column_plus_one}"
    case "$?" in
      1)  break ;;
      2)
        if ! "${RANDOMLY}"; then
          out "and reshuffled the file "
          <"${INPUT}" initial_transform >"${FILE}"
          row="0"
        fi ;;
    esac

    # Print the answer
    # `sed` and `trim_every_line` to remove extras added by `xsv`
    history_current_line \
      | xsv select --no-headers --delimiter '|' "!1,${column_plus_one}" \
      | xsv flatten --no-headers \
      | sed 's/^[0-9]*//' \
      | trim_every_line
  done

  ##############################################################################
  # Print the ${REMIND} list
  if [ -n "${REMIND}" ]; then
    outln '' '######## Reminder ########'
    REMIND="$( out "${REMIND}" | sort | uniq )"  # `out` cause trailing newline

    outln '### Head List ###'
    outln "${REMIND}" | {
      while IFS= read -r head; do
        get_line "${INPUT}" "${head}" \
          | xsv select --no-headers --delimiter '|' "${column}" \
          | trim_every_line
      done
    }

    outln '### Definitions ###'
    outln "${REMIND}" | {
      while IFS= read -r head; do
        outln "########"
        get_line "${INPUT}" "${head}" \
          | xsv flatten --no-headers --delimiter '|' \
          | sed 's/^[0-9]*//' \
          | trim_every_line
      done
    }
  fi
}

################################################################################
# Primary functionality
initial_transform() {
  # -p no-renumber, -s separator, -w number-width, -b body-numbering
  #   -b a: number the blank lines
  #   -p: not actually sure how `nl` handles sections
  #   -w 1: remove the paddings
  #   -s '|': add a pipe after
  # sed filters out empty lines and commented lines, and limits the range
  # then shuffles the input
  history_reset
  <&0 nl -p -s '|' -w 1 -b a \
    | sed -e '/^[0-9]*|[ \t]*$/d' \
      -e '/^[0-9]*|[ \t]*\/\//d' \
      -e "${START_AT},${END_AT}p" \
    | shuf
}

MENU="########  (a/c/d/e/h/l/n/p/q/) 'h' for help, '' for next ########"
display_current_head() {
  outln "${MENU}"
  out "$( history_current_line \
    | xsv select --no-headers --delimiter '|' "${2}" \
    | trim_every_line
  )" " "
}

# TODO: Add a to-remember list

# NOTE: Overwrites ${2} on edits
# Exit code 2 means reguar
# Exit code 3
display_and_menu() {
  display_current_head "${2}" "${4}"
  while : ; do
    case "$( prompt '.*' "" )" in
      h*) outln \
        "  'h' for help" \
        "  'a' to repeat the entry" \
        "  'c' to edit the current entry in \${EDITOR} '${EDITOR}'" \
        "  'd' to lookup the specific word in the dictionary" \
        "  'e' to edit the previous entry in \${EDITOR} '${EDITOR}'" \
        "  'l' to lookup any word in the dictionary" \
        "  'n' to go forward in history" \
        "  'p' to go backward in history" \
        "  'q' to quit" \
        "  ''  to reveal the answer and next entry" \
        ;;
      a*) outln "Again"; display_current_head "${2}" "${4}" ;;
      c*)
        out "Edited "
        "${EDITOR:-vim}" \
          "+normal! $( history_current_line | row_from_line )G" \
          "${1}"
        return 2 ;;
      d*)
        sdcv --data-dir "${STARDICT_DIR}" "${4}"
        out "Dictionary " ;;
      e*)
        out "Edited "
        "${EDITOR:-vim}" \
          "+normal! $( get_line "${2}" "${PREVIOUS:-1}" \
            | row_from_line )G" \
          "${1}"
        return 2 ;;
      l*)
        outln "Use Ctrl-D to return"
        sdcv --data-dir "${STARDICT_DIR}"
        out "Dictionary back " ;;
      n*)
        PREVIOUS="$( history_current_row )"
        history_forward
        display_current_head "${2}" "${4}"
        outln "" "$(( $( out "${HISTORY_FORWARD}" | wc -l ) - 1 )) in front" ;;
      p*)
        PREVIOUS="$( history_current_row )"
        history_backward
        display_current_head "${2}" "${4}"
        outln "" "$(( $( out "${HISTORY_FORWARD}" | wc -l ) - 1 )) in front" ;;
      r*)
        REMIND="${REMIND}$( history_current_line | row_from_line )${NL}"
        out "Add to reminder list " ;;
      q*)  return 1 ;;
      *)   break ;;
    esac
  done
  PREVIOUS="${3}"
  return 0
}

################################################################################
# History
NL='
'
history_reset() {
  HISTORY_BACKWARD="${NL}"  # "\n1\n2\n" preceeded and succeeded by newline
  HISTORY_FORWARD="1${NL}"  # suceeded but not preceeded (see `history_get`)
}
HISTORY_LENGTH="30"       # Negative number for unlimited
history_reset

history_backward() {
  if [ -n "${HISTORY_BACKWARD#${NL}}" ]; then
    HISTORY_BACKWARD="${HISTORY_BACKWARD%${NL}}"
    HISTORY_FORWARD="${HISTORY_BACKWARD##*${NL}}${NL}${HISTORY_FORWARD}"
    HISTORY_BACKWARD="${HISTORY_BACKWARD%${NL}*}${NL}"
  fi
}
history_forward() {
  if [ -n "${HISTORY_FORWARD#*${NL}}" ]; then  # Need at least one entry
    HISTORY_BACKWARD="${HISTORY_BACKWARD}${HISTORY_FORWARD%%${NL}*}${NL}"
    HISTORY_FORWARD="${HISTORY_FORWARD#*${NL}}"
  fi
}

history_push() {
  HISTORY_BACKWARD="${HISTORY_BACKWARD}${HISTORY_FORWARD%%${NL}*}${NL}"
  if [ "${HISTORY_LENGTH}" -ge 0 ] && \
     [ "$( outln "${HISTORY_BACKWARD}" | wc -l )" -gt "${HISTORY_LENGTH}" ]
     # ${HISTORY_BACKWARD} has an extra line so use -gt
  then
    HISTORY_BACKWARD="${NL}${HISTORY_BACKWARD#${NL}*${NL}}"
  fi
  HISTORY_FORWARD="${1}${NL}"
}
# Not padding both sides of ${HISTORY_FORWARD} with newline so this is easier
history_current_row() { out "${HISTORY_FORWARD%%${NL}*}"; }
history_current_line() { get_line "${FILE}" "$( history_current_row )" ; }

################################################################################
# Helpers
trim_every_line() { sed -e 's/^ *//' -e 's/ *$//'; }
get_line() { sed -n "${2}p" "${1}"; }
row_from_line() { <&0 xsv select --delimiter '|' 1; }


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
