#!/usr/bin/env sh
  # Display an fzf selectable bookmark list and feed it to browser choice menu

# Dependencies
bookmarks="${DOTENVIRONMENT}/bookmarks.csv"
runbrowser="browser-fzf.sh" 

line="$(<"${bookmarks}" \
  awk '
    BEGIN{ FS="|" }
    { gsub(/^ *| *$/, "", $2) }              # trim leading/trailing spaces
    /^[0-9]*\|$/{ next }                     # skip blank lines
    !/^ *$/{ printf("%3s %s%s\n",NR,$1,$2) } # less than 1000 bookmarks
  ' | fzf --no-sort --layout=reverse-list 
)"

[ "$?" = "130" ] && exit 130 # If Ctrl-c received before fzf, same error code
[ -z "${line}" ]   && exit 1 # If a blank (ie. invalid) link is entered

lineno="$(printf '%s' "${line}" | awk '{print $1}')"
url="$(<"${bookmarks}" awk -v FS="|" '
  (NR == '"${lineno}"') {
    gsub(/^ *| *$/, "", $3);  # Could also change FS back and do $3 = $3 trick
    print $3;
  }'
)"

"${runbrowser}" "${url}: " "${url}"
