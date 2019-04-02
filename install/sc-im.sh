#!/usr/bin/env sh

require() { command -v "$1" >/dev/null 2>&1; }
die() { exitcode="$1"; shift 1; printf %s\\n "$@" >&2; exit "${exitcode}"; }

require scim || die 1 'already installed'

apt install unstable-repo
apt install sc-im
