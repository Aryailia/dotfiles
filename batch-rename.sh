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

  -
    Special argument that instructs reading from STDIN. Only once though.

  -h, --help
    Displays this help message
  -f, --file FILEPATH
  -d, --direct ARGUMENT
  -r, --relative-path-to PATH
EOF
}



# Just separating out for clarity
process_options() {
  # Flags
  RELATIVE_TO=''  # `pwd` reads blank as current directory
  I=''  # Input files

  # Options processing
  literal='false'
  while [ "$#" -gt 0 ]; do
    if ! "${literal}"; then
      # Split grouped single-character arguments up, and interpret '--'
      # Parsing '--' here allows "invalid option -- '-'" error later
      case "$1" in
        --)      literal='true'; shift 1; continue ;;
        -[!-]*)  opts="$( outln "${1#-}" | sed 's/./ -&/g' )" ;;
        --?*)    opts="$1" ;;
        *)       opts="regular" ;;
      esac

      # Process arguments properly now
      for x in ${opts}; do case "$x" in
        -h|--help)  show_help; exit 0 ;;

        -f|--file)  I="$I${NEWLINE}$( cat "$2"; printf a )"
                    I="${I%a}"; shift 1 ;;
        -d|--direct)  I="$I${NEWLINE}$2"; shift 1 ;;
        -r|--relative-path-to)  RELATIVE_TO="$2"; shift 1 ;;
        -)  I="$I${NEWLINE}$( cat -; printf a )"; I="${I%a}" ;;  # STDIN

        *)
          [ -e "$1" ] || die 1 FATAL "'$1' is an invalid file"
          I="$I${NEWLINE}$( normalise_path "$1"; printf a )"; I="${I%a}"
      esac done
    else
      [ -e "$1" ] || die 1 FATAL "'$1' is an invalid file"
      I="$I${NEWLINE}$( normalise_path "$1"; printf a )"; I="${I%a}"
    fi
    shift 1
  done
}

# Handles single character-options joining (eg. pacman -Syu)
main() {
  process_options "$@"

  [ -z "$I" ] && { show_help; exit 1; }
  # Reverses the order and checks the files exist
  # If ${RELATIVE_TO} is set, change paths relative to that file
  BEFORE="$I"
  BEFORE="$( simplify_BEFORE_to_relpath "${RELATIVE_TO}"; printf a )"
  I="${BEFORE%a}"

  # Edit the file
  AFTERFILE="$( mktemp -p "${TMPDIR:-/tmp}" )"
  trap 'rm -f "${AFTERFILE}" >/dev/null 2>&1' EXIT
  start="$( outln "${HEADER}" | wc -l )"
  out "${HEADER}" "$I" >"${AFTERFILE}"
  "${EDITOR:-vim}" -c "$(( start + 1 ))" -- "${AFTERFILE}"

  # Note these commands eat BEFORE and AFTER
  # Check every path has a target
  BEFORE="$I"
  AFTER="$( cat "${AFTERFILE}"; printf a )"; AFTER="${AFTER%?a}"
  count="$( count pop_BEFORE_to_B )"
  if [ "${count}" != "$( count pop_AFTER_to_A )" ]; then
    die 1 FATAL \
      "Number of paths before and after your edit do not match" \
      "Perhaps you deleted or added a path by accident" \
      "or the paths are not all preceded by either '././' or '/./"
  fi

  # Perform the move
  BEFORE="$I"
  AFTER="$( cat "${AFTERFILE}"; printf a )"; AFTER="${AFTER%?a}"
  mass_move_BEFORE_to_AFTER "${count}"
}



################################################################################
# Core functionality

# Apply appending '\n' to $1 as well to preserve trailing newline cases, the
# basic utilities like `tee` want trailing '\n' in general (`tee` makes sure a
# trailing newline would be added, merging non newline case into newline case)
#
# Looping `pop` on "${check}" instead of `tee | awk 'system test -e` 
# because cannot deal with trailing newline added by awk (in awkscript cannot
# determine when last record  reached). Awkscript method also less readable
HEADER="$( <<EOF cat -
# Only can have comments before the very first line of files
# Newline placement is quite important
#
# Each record immediately after start-of-file or "\\n" begins with:
#   '/./' if absolute pathname
#   '././' if relative pathname
# This delimiting newline is not counted towards filenames.
# To be exact records are separated by "\\n/./" or "\\n././"
# Eg. if each line of the following starts after the pipe '|':
#   |/./a
#   |
#   |././b
#   |/./c
# Represents "/a\\n" "./b" and "/c"
EOF
)"

mass_move_BEFORE_to_AFTER() {
  error_msg=''
  error_num='0'
  good_num='0'
  skip_num='0'

  while :; do
    # Breaking condition
    # `break` when `pop` exits its subshell (does not find ${pattern})
    pop_BEFORE_to_B || break
    pop_AFTER_to_A  || break

    [ "$B" = "$A" ] && { skip_num="$(( skip_num + 1 ))"; continue; }

    # To be comprehensive, check if all source files exist
    if [ ! -e "$B" ]; then
      error_num="$(( error_num + 1 ))"
      error_msg="${error_msg}$( outln '' "ERROR: Path is invalid '$B'" )"
      continue
    fi

    # No overwriting (or we would have to care about order)
    # TODO: consider adding a flag for forcing overwrite?
    if [ -e "$A" ]; then
      error_num="$(( error_num + 1 ))"
      error_msg="${error_msg}$( outln '' \
        'ERROR: Path already occupied, this does not support overwriting' \
        "'$B'" '->' "'$A'" \
      )"
      continue
    fi

    # Do the move
    if mv "$B" "$A"; then
      good_num="$(( good_num + 1 ))"
    else
      error_num="$(( error_num + 1 ))"
      error_msg="${error_msg}$( outln \
        "ERROR: Failed to \`mv\`... Permissions error?" \
        "'$B'" '->' "'$A'" \
      )"
    fi
  done

  # Report
  alert "$(
    outln "Processed $1 path(s)"
    [ "${good_num}" -gt 0 ]  && outln "🚚 ${good_num} files moved"
    [ "${skip_num}" -gt 0 ]  && outln "🚸 ${skip_num} files skipped"
    [ "${error_num}" -gt 0 ] && outln "⛔ ${error_num} files failed"
    [ -n "${error_msg}" ]    && outln "${error_msg}"
  )"
  [ -n "${error_msg}" ] && soutln "${error_msg}" >&2
}

################################################################################
# Optional functionality

# TODO: make this more general? Probably not worth the effort
#       Only when already inside '$1' folder
simplify_BEFORE_to_relpath() {
  cwd_logical="$(  pwd -L "$1"; printf a )"; cwd_logical="${cwd_logical%?a}"
  cwd_physical="$( pwd -P "$1"; printf a )"; cwd_physical="${cwd_physical%?a}"
  # Additionally checks if all these files exist due to `pop_BEFORE_to_B`
  while pop_BEFORE_to_B; do
    if [ -z "$1" ]; then
      out "${NEWLINE}$B"  # The case when the option is not set
    elif [ "$B" != "${B#/."${cwd_logical}"}" ]; then
      out "${NEWLINE}./.${B#/."${cwd_logical}"}"
    elif [ "$B" != "${B#/."${cwd_physical}"}" ]; then
      out "${NEWLINE}./.${B#/."${cwd_physical}"}"
    else
      out "${NEWLINE}$B"  # Leave the path untouched if not simplifiable
    fi
  done #| reverse
}



################################################################################
# Helpers
count() {
  _count="0"
  while "$1"; do _count="$(( _count + 1 ))"; done
  out "${_count}"
}

normalise_path() {
  _base="$( basename -- "$1"; printf a )"; _base="${_base%?a}"
  _dir="$( dirname -- "$1"; printf a )";   _dir="${_dir%?a}"

  if [ "${_dir}" = '/' ]; then
    if [ "${_base}" = '/' ]
      then out '/./'
      else out "/./${_base}"
    fi
  elif [ "${_dir}" != "${_dir#/}" ]; then
    out "/.${_dir}/${_base}"
  else
    out "./${_dir}/${_base}"
  fi
}



NEWLINE='
'
pop_AFTER_to_A() {
  if [ "${AFTER}" != "${AFTER##*"${NEWLINE}"/./}" ]
    then A="${AFTER##*"${NEWLINE}"/./}"
    else A="${AFTER##*"${NEWLINE}"././}"
  fi
  AFTER="${AFTER%"$A"}"
  A="${AFTER##*"${NEWLINE}"}$A"
  AFTER="${AFTER%"${NEWLINE}"*}"
  test -n "${AFTER}"
}

pop_BEFORE_to_B() {
  B="${BEFORE##*"${NEWLINE}"*/./}"
  BEFORE="${BEFORE%"$B"}"
  B="${BEFORE##*"${NEWLINE}"}$B"
  BEFORE="${BEFORE%"${NEWLINE}"*}"
  test -e "$B"
}

alert() { notify.sh "$1"; printf %s\\n "$@" >&2; }

out() { printf %s "$@"; }
outln() { printf %s\\n "$@"; }
errln() { printf %s\\n "$@" >&2; }
die() { c="$1"; errln "$2: '${name}' -- $3"; shift 3; errln "$@"; exit "$c"; }

main "$@"
