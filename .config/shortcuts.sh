#!/usr/bin/env sh

# prints in the format of escaped quotes, itself quoted, with a trailing space
# eg. <'spaces'\'and quotes.txt' >  which will matches <spaces'and quotes.txt>
out() { printf "'%s' " "$@"; }

out "a" "${HOME}/.vim/after"
out "b" "${HOME}/blog"
out "c" "${HOME}/.config"
out "d" "$(c.sh downloads)"
out "e" "${DOTENVIRONMENT}"
out "i" "${HOME}/interim"
#out "m" "${HOME}/Music"
out "n" "${DOTENVIRONMENT}/notes"
out "p" "${HOME}/projects"
out "s" "${SCRIPTS}"