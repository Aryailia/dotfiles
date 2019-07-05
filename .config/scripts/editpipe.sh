#!/usr/bin/env sh
#https://stackoverflow.com/questions/10686183/pipe-vim-buffer-to-stdout

# Contemplate making our own implementation of `mktemp`
# Technically `mktemp` is not in the POSIX specification
editor="${EDITOR:-vim}"
temp="$(mktemp -p "${TMDPIR:-/tmp}")"
trap 'rm ${temp}' EXIT

<&0 cat - >"${temp}" || exit $?                       # Slurp stdin into ${temp}
</dev/tty "${editor}" "${temp}" >/dev/tty || exit $?  # Launch editor
cat "${temp}"                                         # Continue with pipe
