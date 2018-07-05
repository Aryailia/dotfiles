#!/usr/bin/env sh

directory=${0%/*}
cd -P scripts
directory=$(pwd)
helpers="$directory/helpers"
websites="$HOME/locales/websearches.txt"

browser="$1"
search="$2"
query="$3"

extract() {
  cat - | awk '
    BEGIN{FS="|"}
    /^\/\//{next}           # ignore commments
    {$0=$'"$1"'}            # extract
    {gsub(/^\s*|\s*$/, "")} # trim
    {print}
  '
}

[ -z "$browser" ] && browser=$($helpers/prompt-browser.sh | rofi -dmenu)
[ -z "$search" ] &&   search=$( \
  extract <"$websites" 2 | rofi -dmenu -p "$browser")
[ -z "$query" ] &&     query=$(rofi -dmenu -p "$browser $search")

printf '%s %s' "$browser" "$( \
  printf $(grep <"$websites" "$search" | extract 3) "$query")"
