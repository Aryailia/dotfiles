#!/usr/bin/env sh
# :!console %self
bookmarks="$DOTENVIRONMENT/bookmarks.csv"
promptbrowser="$(dirname "$0")/helpers/prompt-browser.sh" 
runbrowser="$(dirname "$0")/browser-fzf.sh" 

line="$(< "$bookmarks" awk '
    BEGIN{ FS="|" }
    { gsub(/^ *| *$/, "", $2) }              # trim leading/trailing spaces
    /^[0-9]*\|$/{ next }                     # skip blank lines
    !/^ *$/{ printf("%3s %s%s\n",NR,$1,$2) } # less than 1000 bookmarks
  ' | fzf --no-sort --layout=reverse-list 
)"
  #| awk '{print $1}'

error=$?
[ "$error" = "130" ] && exit 130 # If we Ctrl-c, same error code
[ -z "$line" ] && exit 1 # If a blank (ie. invalid) link is entered

lineno="$(printf '%s' "${line}" | awk '{print $1}')"
url="$(< "${bookmarks}" \
  sed "${lineno}q;d" \
  | awk 'BEGIN{FS="|"}{print $3}' \
  | sed 's/^ *\| *$//g'
)"

"$runbrowser" "${url}: " "$url"
