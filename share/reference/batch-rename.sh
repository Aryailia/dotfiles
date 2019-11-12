#!/usr/bin/env sh

name="$( basename "$0"; printf a )"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name}

DESCRIPTION
  There are two modes.
  In default mode, each parameter is intepreted as a path to use
  In mass mode, each parameter is interpreted as lists

OPTIONS
  --
    Special argument that prevents all following arguments from being
    intepreted as options.
EOF
}

# Globals
# Three representations. Unique absolute paths '/./' or relative paths '././'
GREP_REGEXP='^\.\?/\./'
AWK_REGEXP='^\.?\/\.\/'
EX_REGEXP='^\.\{0,1\}/\./'

FLAG_SIMPILY_TO_RELPATH='false'
FLAG_MASS='false'

main() {
  # Options processing
  args=''; literal='false'
  for arg in "$@"; do
    "${literal}" || case "${arg}" in
      --)  literal='true'; continue ;;
      -h|--help)  show_help; exit 0 ;;
      -m|--mass|--mass-mode)           FLAG_MASS='true' ;;
      -s|--simplify-to-relative-path)  FLAG_SIMPILY_TO_RELPATH='true' ;;
      *)  args="${args} $( soutln "${arg}" | eval_escape )" ;;
    esac
    "${literal}" && args="${args} $( soutln "${arg}" | eval_escape )"
  done

  [ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"

  BEFORE="$( mktemp -p "${TMPDIR:-/tmp}" )"
  CHECK="$(  mktemp -p "${TMPDIR:-/tmp}" )"  # To check if the files exist
  AFTER="$(  mktemp -p "${TMPDIR:-/tmp}" )"
  trap 'rm -f "${AFTER}" "${CHECK}" "${BEFORE}" >/dev/null 2>&1' EXIT

  if "${FLAG_MASS}"
    then for f in "$@"; do soutln "$f" | process; done
    else for f in "$@"; do normalise_path "$f"; done | process
  fi
}


process() {
  # Checking all the paths before we open the editor
  <&0 tee "${BEFORE}" "${CHECK}" >/dev/null
  mutate_check_if_exists "${CHECK}" || exit "$?"

  # Check needs to be the final endpoint
  if "${FLAG_SIMPILY_TO_RELPATH}"
    then simplify_to_relpath "${BEFORE}" >"${CHECK}"
    else cp "${BEFORE}" "${CHECK}"
  fi

  # Print to the temp files (also easy to enter manual tests)
  # Only want one pipe to ${BEFORE} and ${AFTER}, so use ${CHECK} for input
  { <<EOF cat - "${CHECK}"
${HEADER}

EOF
} | tee "${BEFORE}" "${AFTER}" >/dev/null

  # The titular open in editor
  start="$( expr "$( soutln "${HEADER}" | wc -l )" + 2 )"
  "${EDITOR:-vim}" -c "${start}" -- "${AFTER}"  # move to after header
  #"${EDITOR:-vim}" -c '$' -- "${AFTER}"      # move to last line
  #"${EDITOR:-vim}" -- "${AFTER}"

  mass_move "${BEFORE}" "${AFTER}"
}




################################################################################
# Main functionality

# Check if files exist before opening in editor
# Format check?
mutate_check_if_exists() {
  while :; do  # Exit if files to rename do not exist
    # `break` when `ex` from `pop` errors (does not find ${pattern})
    file="$( pop "$1" || exit 1; printf a )" || break; file="${file%?a}"
    [ -e "${file}" ] || { alert "'${file}' does not exist"; return 1; }
  done
}

mass_move() {
  error_msg=''
  path_num="$( grep -ce "${GREP_REGEXP}" "$1" )"
  error_num='0'
  good_num='0'
  skip_num='0'

  [ "${path_num}" = "$( grep -ce "${GREP_REGEXP}" "$2" )" ] || {
    alert "$( soutln \
      "Number of paths before and after your edit do not match" \
      "Perhaps you deleted or added a path by accident" \
      "or the paths are not all preceded by either '././' or '/./" \
    )"
    exit 1
  }

  while :; do
    # Breaking condition
    # `break` when `pop` exits its subshell (does not find ${pattern})
    from="$( pop "$1" || exit 1; printf a )" || break; from="${from%?a}"
    into="$( pop "$2" || exit 1; printf a )" || break; into="${into%?a}"

    [ "${from}" = "${into}" ] && { skip_num="$(( skip_num + 1 ))"; continue; }

    # To be comprehnesive, already checked `mutate_check_if_exists`
    if [ ! -e "${from}" ]; then
      error_num="$(( error_num + 1 ))"
      error_msg="${error_msg}$( soutln '' \
        "ERROR: Path is invalid '${from}'" \
      )"
      continue
    fi

    # No overwriting (or we would have to care about order)
    # TODO: consider adding a flag for forcing overwrite?
    if [ -e "${into}" ]; then
      error_num="$(( error_num + 1 ))"
      error_msg="${error_msg}$( soutln '' \
        'ERROR: Path already occupied, this does not support overwriting' \
        "'${from}'" \
        '->' \
        "'${into}'" \
      )"
      continue
    fi

    # Do the move
    if mv "${from}" "${into}"; then
      good_num="$(( good_num + 1 ))"
    else
      error_num="$(( error_num + 1 ))"
      error_msg="${error_msg}$( soutln \
        'ERROR: Failed to `mv`... Permissions error?' \
        "'${from}'" \
        '->' \
        "'${into}'" \
      )"
    fi
  done

  # Report
  alert "$(
    soutln "Processed ${path_num} path(s)"
    [ "${good_num}" -gt 0 ]  && soutln "🚚 ${good_num} files moved"
    [ "${skip_num}" -gt 0 ]  && soutln "🚸 ${skip_num} files skipped"
    [ "${error_num}" -gt 0 ] && soutln "⛔ ${error_num} files failed"
    [ -n "${error_msg}" ]    && soutln "${error_msg}"
  )"
  [ -n "${error_msg}" ] && soutln "${error_msg}" >&2
}

################################################################################
# Apply appending '\n' to $1 as well to preserve trailing newline cases, the
# basic utilities like `tee` want trailing '\n' in general (`tee` makes sure a
# trailing newline would be added, merging non newline case into newline case)
#
# Looping `pop` on "${check}" instead of `tee | awk 'system test -e` 
# because cannot deal with trailing newline added by awk (in awkscript cannot
# determine when last record  reached). Awkscript method also less readable
HEADER="$(<<EOF cat -
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



################################################################################
# Helpers

# Get the bottom-most path in the list
pop() {
  awk -v FS="" '
    BEGIN { start = 0; }
    /'"${AWK_REGEXP}"'/ { start = 1; output = ""; }  # Reset
    start { output = output $0 "\n"; }
    END { printf("%s", output); }
  ' "$1"

  ## `ex` runs into trouble with ́'././é' so switched to using `awk`
  ## `ex` either printing wrong or too out of date to deal with unicode?
  #soutln "set wrapscan|1|?${EX_REGEXP}?,\$print|quit" | ex "$1" | sed '1d'

  # Removes the first pathname. Exits with error if none found
  soutln "set wrapscan|1|?${EX_REGEXP}?,\$delete|write|quit" \
    | ex -- "$1" >/dev/null
}

# Checks for unique absolute or unique relative paths
simplify_to_relpath() {
  cwd_logical="$(  pwd -L; printf a )"; cwd_logical="${cwd_logical%?a}"
  cwd_physical="$( pwd -P; printf a )"; cwd_physical="${cwd_physical%?a}"
  while :; do
    path="$( pop "$1" || exit 1; printf a )" || break; path="${path%?a}"
    if [ "${path}" != "${path#/."${cwd_logical}"}" ]; then
      soutln "./.${path#/."${cwd_logical}"}"
    elif [ "${path}" != "${path#/."${cwd_physical}"}" ]; then
      soutln "./.${path#/."${cwd_physical}"}"
    else
      soutln "${path}"
    fi
  done | reverse
}

# Reverse
reverse() {
  # Goal: Get all paths to exist one line by tokenising for feed to tac
  # 1. Replace '@' -> '@a', then newline "\n" -> '@n' except when newlines
  #    exists between path entries
  # 2. `tac` to reverse order
  # 3. Detokenise @a and @n

  # Need trailing newline because UNIX utils need a trailing newline (or EOF)
  # ':a;{N;$!ba}' append everything but last line into pattern space
  # Then do all the substitutions after '}'
  # BSD apparently needs labels to be separated
  # https://stackoverflow.com/questions/1251999/ - Isaac for adding brackets
  sed -e ':a' -e '{N;$!ba}' -e 's#@#@a#g' -e 's#\n#@n#g' \
    -e 's#@n/./#\n/./#g' -e 's#@n././#\n././#g' \
    | tac \
    | sed -e 's#@n#\n#g' -e 's#@a#@#g'
}

normalise_path() {
  base="$( basename -- "$1"; printf a )"; base="${base%?a}"
  dir="$( dirname -- "$1"; printf a )";   dir="${dir%?a}"

  if [ "${dir}" = '/' ]; then
    if [ "${base}" = '/' ]
      then soutln '/./'
      else soutln "/./${base}"
    fi
  elif [ "${dir}" != "${dir#/}" ]; then
    soutln "/.${dir}/${base}"
  else
    soutln "./${dir}/${base}"
  fi
}

soutln() { printf %s\\n "$@"; }
alert() { notify.sh "$1"; printf %s\\n "$@" >&2; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
