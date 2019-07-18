#!/usr/bin/env sh
# This should be completely robust way to rename files via ${EDITOR}
#
# Having non-existent pathnames causes or records (awk-sense) being deleted
# will cause the rename to stop before anything happens.
# Continues execution when `mv` fails or tries to replace an existing file
#
# Non-simplified paths  '/a/././../b' = '/b' can work
#
# Using `ex` as it can edit in place and because it is part of POSIX, portable
# TODO: This does not validate the format before passing to user to edit

# Helper functions
puts() { printf %s\\n "$@"; }
alert() { notify.sh "$1"; }
#alert() { puts "$@" >&2; }
# `ex` adds a newline like other basic utils eg. `basename`
pattern='?^\.\{0,1\}/\./?,$'
grep_pattern='^\.\?/\./'
# On error, it will still print? (will be empty)
pop() {
  puts "set wrapscan|1|${pattern}print|quit" | ex "$1" | sed '1d'
  puts "set wrapscan|1|${pattern}delete|write|quit" | ex "$1" >/dev/null
}


# Main
[ -n "$1" ] || { alert 'No files provided'; exit 1; }

before="$( mktemp -p "${TMPDIR:-/tmp}" )"
after="$(  mktemp -p "${TMPDIR:-/tmp}" )"
check="$(  mktemp -p "${TMPDIR:-/tmp}" )"
trap 'rm -f "${check}" "${after}" "${before}" >/dev/null 2>&1' EXIT

# Apply appending '\n' to $1 as well to preserve trailing newline cases, the
# basic utilities like `tee` want trailing '\n' in general (`tee` makes sure a
# trailing newline would be added, merging non newline case into newline case)
#
# Looping `pop` on "${check}" instead of `tee | awk 'system test -e` 
# because cannot deal with trailing newline added by awk (in awkscript cannot
# determine when last record  reached). Awkscript method also less readable
{ <<EOF cat -
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

$1
EOF
} | tee "${check}" "${before}" "${after}" >/dev/null
false && while :; do  # Exit if files to rename do not exist
  # `break` when `ex` from `pop` errors (does not find ${pattern})
  file="$( pop "${check}" || exit 1; printf a )" || break; file="${file%?a}"
  [ -e "${file}" ] || { alert "'${file}' does not exist"; exit 1; }
done

# Open the files, move to last line
#"${EDITOR}" "${after}"
"${EDITOR}" -c '$' -- "${after}"

total="$( grep -ce "${grep_pattern}" "${before}" )"
success_count='0'

if [ "${total}" = "$( grep -c "${grep_pattern}" "${after}" )" ]; then
  errors=''
  while :; do
    # `break` when `ex` from `pop` errors (does not find ${pattern})
    from="$( pop "${before}" || exit 1; printf a )" || break; from="${from%?a}"
    into="$( pop "${after}" || exit 1; printf a )"  || break; into="${into%?a}"

    # Already check if ${from} exists in previous `while` loop
    if [ "${from}" != "${into}" ]; then
      if [ -e "${into}" ]; then
        errors="${errors}$(
          puts "ERROR: '${from}' -> '${into}' already exists"
        )"
      else
        success_count="$(( success_count + 1 ))"
        mv "${from}" "${into}" \
          || errors="${errors} 'ERROR: Permission error? '${from}' -> '${into}'"
      fi
    fi
  done
  alert "$(
    error_count="$( puts "${errors}" | grep -ce '^ERROR' )"
    neither_count="$( expr "${total}" - "${error_count}" - "${success_count}" )"

    [ "${success_count}" -gt 0 ] && puts "🚚 ${success_count} files moved"
    [ "${neither_count}" -gt 0 ] && puts "🚸 ${neither_count} files skipped"
    [ "${error_count}" -gt 0 ]   && puts "⛔ ${error_count} files failed"
    [ -n "${errors}" ]           && puts "${errors}"
  )"
fi
