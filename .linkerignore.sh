#!/usr/bin/env sh

# The requirement is to print out a shell-quoted list that has no newlines
# This is to be read by eval, newlines break eval
# Going through all this hassel so all filen paths are supported (trailing
# newlines, intermediary newlines, quotes, etc.)

# prints in the format of escaped quotes, itself quoted, with a trailing space
# eg. <'spaces'\'and quotes.txt' >  which will matches <spaces'and quotes.txt>
out() { printf "'%s' " "$@"; }

# Won't break, but you probably do not want these linked
out './.linkerignore.sh'
out './linker.sh'
out './.config/scripts/*'
out './.config/nvim/*'
out './.git/*'
out './.gitignore'
out './.git_template/*'
out '*.swp'

# Custom stuff
out './share/*'
out './install/*'
out './README.md'
