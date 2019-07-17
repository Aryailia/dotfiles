#!/usr/bin/env sh

name="$(printf %s\\na "$1")"; name="${name%?}"
touch -- "${name}"
