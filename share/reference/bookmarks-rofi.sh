#!/bin/sh
# :!console sh %self

# A bookmark launcher with rofi with a second rofi menu for which browser
# - Nearly all logic is viewable from this script file
# - Only need to make changes here and to the prompt-browser script
# - The rofi menu can search by any (combo), title, url, or tags
# - Specifically that order because title and tags are one keypress away
# - Fuzzy searching and tags can be searched out-of-order
#
# The syntax of the bookmark file is:
# // Optional comments
# | title | url | tags |
# Should be resizeable with tabular plugins: vimwiki/tabular/orgmode/etc.
# Tags are prepended with a hashtag (#) for easy searching in combo menu
# Tags are space seperated to allow for out-of-order fuzzy search
# eg. "#japanese #grammar"  can be found with "#gr #jp"
#
# Control flow of is determined by type of arguments passed:
# 0) NOTE: May want to run this with: SEARCH_TYPE=0 $0
# 1) No arguments or pre-set variables inits rofi
# 2) SEARCH_TYPE is preset but no arguments, changes how rofi menu is populated
# 3) Single bookmark: <data> <id>, ID is its line number in the file
#    
# 4) Has browser and 

# TODO: Maybe add mozilla/netscape's bookmark.xml parsing?
# TODO: Help file

# Tightly-coupled-to-environment file location dependencies
directory=${0%/*}
helpers="$directory/helpers"
bookmarks="$HOME/locales/bookmarks.txt"
promptbrowser="$helpers/prompt-browser.sh"

# Creates the intermediary files for parameter passing for rofi script mode
create_populator() {
  filename="$helpers/bookmark-$1.sh"
  content=$(printf '%s\n%s\n%s' \
    "#!/bin/sh" \
    "# please look to the rofi-prompt-bookmarks.sh for more" \
    "SEARCH_TYPE=\"$1\" \"$0\" \"\$*\"")

  # Save on a disk write if possible
  [ "$(cat "$filename")" != "$content" ] && printf '%s' "$content" > "$filename"
  chmod 744 "$filename"
  shellcheck "$filename"
}

# Gets the desired column and the line number (introduced by awk)
extract_entry_and_id() {
  case "$1" in
    title) </dev/stdin awk 'BEGIN{FS="|"}{$0=$1$2}{print}' ;;
    tags)  </dev/stdin awk 'BEGIN{FS="|"}{$0=$1$3}{print}' ;;
    url)   </dev/stdin awk 'BEGIN{FS="|"}{$0=$1$4}{print}' ;;
    *)
      # If using different shell could do {cat - | tee >() >() >()}
      # Storing in variable has problem of maybe running out of memory
      # Which may be a concern for very large bookmark files
      # Temp files is next best option for dash, though there are others
      stdin="$(cat -)"
      printf '%s\n' "$stdin" | extract_entry_and_id title
      printf '%s\n' "$stdin" | extract_entry_and_id tags
      printf '%s\n' "$stdin" | extract_entry_and_id url
  esac
}

# The state machine
# The state mode of Rofi works by calling the same script at each selection,
# with previous choice as the parameter. Any stdout will populate the menu
if [ -z "$*" ]; then
  # 1) Initial run, no arguments
  if [ -z "$SEARCH_TYPE" ]; then
    # Because cannot pass arguments to script mode rofi, have to create shell
    # script files that cal
    # haveCreate three files to basically call pass
    create_populator title
    create_populator tags
    create_populator url
    create_populator all

    title="TITLE:$helpers/bookmark-title.sh"
    tags="TAGS:$helpers/bookmark-tags.sh"
    url="URL:$helpers/bookmark-url.sh"
    all="/:$helpers/bookmark-all.sh" # 'all' handled a bit differently 
    rofi -show '/' -modi "$all,$title,$url,$tags" -matching fuzzy

  # SEARCH_TYPE=<populator-type> $0
  # 2) Called by rofi 
  else
    <"$bookmarks" awk '
      {$0=NR$0}           # append row number (to after the table last bar)
      /^[0-9]*\/\//{next} # skip over C-like comments
      !/^[0-9]*$/{print}  # skip blanks lines (awk added row number)
    ' | extract_entry_and_id "$SEARCH_TYPE" \
      | sort -k2
  fi

# After a URL is entered
# Third step that determines the url from the id and then ask
elif printf '%s' "$*" | grep -q '^[0-9]\+ \+.\+$'; then
  id="$*"
  id="${id%%\ *}"
  url="$(<"$bookmarks" sed "${id}q;d" | extract_entry_and_id url)"
  url="${url%\ *}"

  # Append the url to all the browser_tags to pass both to the fourth step
  "$promptbrowser" | awk '{$0=$0"  \t '"$url"'"}{print}'

# $0 <browser_tag> <url>
# Last step that extracts the browser_tag of the prompt script and the url
# Does not push anything to stdout to close rofi
else
  browser=$(printf '%s' "$*" | awk '{print $1}')
  url=$(printf '%s' "$*" | awk '{print $2}')
  "$promptbrowser" "$url" "$browser"
fi
