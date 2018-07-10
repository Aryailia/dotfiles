#!/usr/bin/env sh
# :!console %self
bookmarks="$HOME/ime/bcde"
promptbrowser="$(dirname $0)/helpers/prompt-browser.sh" 

line="$(< "$bookmarks" \
  awk "$(printf '%s\n' \
    'BEGIN{ FS="|"}' \
    '{gsub(/^ *| *$/, "", $2)}'\
    '/^[0-9]*\|$/{next}' \
    '!/^ *$/{printf("%3s %s%s\n",NR,$1,$2)}' \
  )" \
  | fzf --no-sort --layout=reverse-list 
)"
  #| awk '{print $1}'

error=$?
[ "$error" = "130" ] && exit 130 # If we Ctrl-c, same error code
[ -z "$line" ] && exit 1 # If a blank (ie. invalid) link is entered

lineno="$(printf '%s' "$line" | awk '{print $1}')"
url="$(< "$bookmarks" \
  sed "${lineno}q;d" \
  | awk 'BEGIN{FS="|"}{print $3}' \
  | sed 's/^ *\| *$//g'
)"
browser="$("$promptbrowser" | fzf --no-sort --layout=reverse-list)"

error=$?
[ "$error" = "130" ] && exit 130 # If we Ctrl-c, same error code
[ -z "$line" ] && exit 1 # If a blank (ie. invalid) link is entered

# Cannot background this otherwise it terminates it
# Not really sure what the best way to approach this is
# Should also check on promptbrowser script as that does both nohup and setsid
# but backgrounds (decided that should background as it is run by others)
nohup setsid "$promptbrowser" "$url" "$browser" >/dev/null 2>&1 # &
