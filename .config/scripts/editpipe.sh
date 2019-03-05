#!/usr/bin/env sh
#https://stackoverflow.com/questions/10686183/pipe-vim-buffer-to-stdout

editor="${EDITOR:-vim}"
temp="$(mktemp)"

<&0 cat - >"${temp}" || exit $?                       # Slurp stdin into ${temp}
</dev/tty "${editor}" "${temp}" >/dev/tty || exit $?  # Launch editor
cat "${temp}"                                         # Continue with pipe
rm "${temp}"
