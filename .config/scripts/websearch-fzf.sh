#!/usr/bin/env sh
  # Search from an Fzf list and feed to browser choice list
  # The websearches are formated in file as a csv

# Dependencies
browserhandler="browser-fzf.sh"
websearches="${DOTENVIRONMENT}/websearches.txt"

# Not using line number as ID because passing $1 would be inconsistent with rofi
# No reason for cli use to have to know what ID a given websearch is
# $0 "1 archwiki" "fcitx" "firefox"
# archwiki<Enter>fcitx<Enter>firefox<Enter>
extract() {
  target="$1"
  <&0 awk -v FS="|" '
    /^[0-9]*\/\//{ next }     # ignore commments
    /^[0-9]*$/{ next }        # ignore blank lines
    { $0 = $('"${target}"') }   # extract
    { gsub(/^\s*|\s*$/, "") } # trim
    { print }
  '
}

search="${1:-$(<"${websearches}" extract 2 | fzf --no-sort --layout=reverse)}"
error=$?
[ "${error}" = "130" ] && exit 130 # If Ctrl-c, exit with that error code
[ -z "${search}" ] && exit 1 # If blank (invalid/Esc), then exit

format="$(<"${websearches}" grep "^[ |]*${search}" | extract 3 | head --lines=1)"

printf "${format}" '[   ] '
read -r query
url="$(printf "${format}" "${query}")"

"${browserhandler}" "${url}: " "${url}"
