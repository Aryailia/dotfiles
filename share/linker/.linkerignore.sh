#!/usr/bin/env sh
# tldr; Just treat the string passed to escape as globs to be checked
# Should be mostly the same as '.gitignore' syntax
#
# The requirement is to print out a shell-quoted list to be read by eval
# then will be used within a case statement (so glob matching)
# eg.
#   escape "Mc'Hattington\*/*"     ->  'Mc'\''Hattington\*/*'
# Which then is run through eval
#   eval 'Mc'\''Hattington\*/*'   ->  "Mc'Hattington\*/*"
# Which then compares every file to this as a glob
#   -> case "${file}" in  Mc'Hattington\*/*) return 0 ;; esac
# Which means everything in folder named "Mc'Hattington*" will be ignored
#
# In other words, treat inside the quotes as globs
#
# See https://www.etalabs.net/sh_tricks.html for explanation
# Added '././' as a unique identifier prefix and a space after
escape() { printf "././%s" "$1" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/' /"; }

# NOTE: Edit below this line
# Won't break, but you probably do not want these linked
escape '.linkerignore.sh'
escape 'linker.sh'
escape '.git/*'
escape '.gitignore'
escape '.git_template/*'
escape '*.swp'

# Custom stuff
escape 'share/*'
escape 'install/*'
escape 'README.md'
escape 'LICENSE'
