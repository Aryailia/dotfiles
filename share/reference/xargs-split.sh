#!/usr/bin/env sh
# TODO: Add addback, '/./home/a' -> 'home/a', need to add '/' ('/home/a')

# NOTE: Delimiter uses glob syntax
# NOTE: Needs the trailing newline/eof like sed, etc. do

#cmd delete ${{
#  printf %s\\n "${fx}" | xargs-split.sh \
#    "$( printf \\n/./ )" sh -c 'trash "/$1"' _
#}}
#cmd copyto ${{
#  destination="$( PROMPT='Copy > ' print-shortcut.sh )" || exit 1
#  [ -d "${destination}" ] || exit 1
#  printf %s\\n "${fx}" | xargs-split.sh "$( printf \\n/./ )" \
#    sh -c 'cp -ivr "$2" "$1"' _ "${destination}"
#  notify.sh "📋 File(s) copied to '${destination}'"
#}}
#cmd moveto ${{
#  destination="$( PROMPT='Move > ' print-shortcut.sh )" || exit 1
#  [ -d "${destination}" ] || exit 1
#  printf %s\\n "${fx}" | xargs-by.sh "$( printf \\n/./ )" \
#    sh -c 'mv -iv "/$2" "$1"' _ "${destination}"
#  notify.sh "🚚 File(s) moved to '${destination}'"
#}}



#delimiter="$1"; shift 1
#<&0 awk -v script="$*" -v FS='' -v RS="${delimiter}" '
#  function eval_escape(sString) {
#    '"gsub(/'/, \"'\\\\''\", sString);"'
#    return "'\''" sString "'\''";
#  }
#  BEGIN { gsub(/\\/, "\\\\", script); }
#  { $0 = eval_escape("/" $0); }  # Add the slash
#  {
#    a = script;
#    system(sprintf("sh -c \"\"" )
#  }
#'



# Stream has to have a trailing newline or eof (similar to `sed` etc.)
# ie. `cat 'filename' | xargs-by.sh` or `print %s\\n "${variables}"`
delimiter="$1"; shift 1

execute() {
  #printf \|%s\|\\n "$1"
  "$@"
}

# via file or via shell variable
buffer=''
last=''
first='true'
process() {
  while [ "${buffer#*${delimiter}*}" != "${buffer}" ]; do
  #if [ "${buffer#*${delimiter}*}" != "${buffer}" ]; then
    entry="${buffer%%${delimiter}*}"
    buffer="${buffer#*${delimiter}}"
    execute "$@" "${entry}"
  #fi
  done
}
# Using `continue` + ${last} to preserve trailing newline which allows
# testing for end-of-file before appending ${buffer} with ${line} (${last})
# Trailing newline/<eof> ensures that everything is fed into ${last}
while IFS= read -r line; do  # '-r' do not interpret backslashes
  "${first}" && { first='false'; last="${line}"; continue; }
  buffer="${buffer}${last}$(printf \\na)"; buffer="${buffer%a}"  # '\n' added
  process "$@"
  last="${line}"
done

#printf %s\\n "last: |${last}|"
#printf %s\\n "line: |${line}|"
#printf %s\\n "buffer: |${buffer}|"
#exit

buffer="${buffer}${last}"  # No '\n' since hit end (trailing newline/<eof>)
process "$@"
# Since delimiters act go in between, this is the final part
execute "$@" "${buffer}"
