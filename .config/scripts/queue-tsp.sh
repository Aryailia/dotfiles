#!/bin/sh
  # $0 <queue as set in constants> <tsp-arg1> <tsp-arg2> ...
# Just a wrapper for tsp

# Parameters
queue="$1"; shift 1

# Helper
fatal() { printf '%s\n' "$@" >&2; exit 1; }

# Dependency checks
tsp=''
if command -v 'ts' >/dev/null 2>&1; then
  tsp='/bin/ts'
elif command -v 'tsp' >/dev/null 2>&1; then
  tsp='/bin/tsp'
else
  fatal 'FATAL: Requires task spooler (ts/tsp)'
fi

constants="${SCRIPTS}/constants.sh" 
[ -x "${constants}" ] || { fatal 'FATAL: `constants.sh` not found'; }

# Main
socket="$(${constants} "${queue}")" || { fatal 'FATAL: Invalid queue'; }
TS_SOCKET="${socket}" ${tsp} "$@"
