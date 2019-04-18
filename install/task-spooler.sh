#!/usr/bin/env sh

require() { command -v "$1" >/dev/null 2>&1; }
puterr() { printf %s\\n "$@" >&2; }
die() { c="$1"; shift 1; for x in "$@"; do puterr "$x"; done; exit "$c"; }

require cc || die 1 "FATAL: Need 'cc' (clang)"
require make || die 1 "FATAL: Need 'make' installed"
require curl || die 1 "FATAL: Need 'curl' to download"

target="ts-1.0.tar.gz"

curl "http://vicerveza.homeunix.net/~viric/soft/ts/${target} -o "${target}""
tar -xvzf "${target}"  # tar is in posix
cd "${target%%.*}"
make
make install PREFIX="${PREFIX}"
