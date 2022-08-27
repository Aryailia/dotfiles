#!/bin/sh

[ "$#" -ge 1 ] || { printf %s\\n "USAGE: $0 <dirname>" >&1; exit 1; }
cd "${1}" || { printf %s\\n "Arg '${1}' is not a valid directory"; exit 1; }

sudo ln -s "${PWD}" '/var/service/'
ls '/var/service'
