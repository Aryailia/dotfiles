#!/usr/bin/env sh
# Makes a snippet (we might use this in the future) and runs tests
# Replace

REPLACE='util-replace.sh'
SNIPPET='replace-snippet.sh'

dir="$( dirname "$0"; printf a )"; dir="${dir%?a}"
cd "${dir}" || { printf %s\\n "Cannot cd to dir of '${REPLACE}'"; exit 1; }

START='# --- start export ---'
CLOSE='# --- close export ---'
NEWLINE='
'

out() { printf %s "$@"; }
outln() { printf %s\\n "$@"; }

eat_till() {
  while IFS= read -r line; do
    printf %s\\n "${line}"
    [ "${line}" = "${1}" ] && break
  done
}

cat "${REPLACE}" | {
  eat_till "${START}" >/dev/null
  body="$( eat_till "${CLOSE}" )"
  printf %s\\n "${body%"${NEWLINE}${CLOSE}"}"
} >"${SNIPPET}"

printf %s\\n "Coppied to snippet ${SNIPPET}" >&2
printf %s\\n "Running tests:" >&2
./tests.sh
