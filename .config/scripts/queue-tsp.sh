#!/usr/bin/env sh
  # $0 <queue as set in constants> <tsp-arg1> <tsp-arg2> ...
# Just a wrapper for tsp

# Parameters
queue="$1"; shift 1

# Helper
die() { printf '%s\n' "$@" >&2; exit 1; }

# Dependency checks
tsp=''
if command -v 'ts' >/dev/null 2>&1; then
  tsp='ts'
elif command -v 'tsp' >/dev/null 2>&1; then
  tsp='tsp'
else
  die 'FATAL: Requires task spooler (ts/tsp)'
fi

constants="${SCRIPTS}/c.sh" 
[ -x "${constants}" ] || die "FATAL: '${constants}' not found"

# Main
socket="$(${constants} "${queue}")" || die 'FATAL: Invalid queue specified'
TS_SOCKET="${socket}" ${tsp} "$@"
