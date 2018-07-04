#!/bin/sh
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
# TODO: Need to do something prompt-browser process blocking UI (synchronous)
#       delete from bottom of file too when completed task
# TODO: Help file

# Tightly-coupled-to-environment file location dependencies
directory=${0%/*}
helperdir="$directory/helpers"
bookmarks="$HOME/ime/bookmarks.txt"
promptbrowser="$direcotry/prompt-browser"

# Creates the intermediary files for parameter passing for rofi script mode
create_populator() {
  filename="$helperdir/bookmark-$1.sh"
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
    title) cat - | sed 's/^| *\(.*\)| *#.*|\([0-9]*\)$/\1 \2/' ;;
    tags)  cat - | sed 's/^.*| *\(#.*\)| *http.*| *\([0-9]*\)$/\1 \2/' ;;
    url)   cat - | sed 's/^.*| *\(http.*\)|\([0-9]*\)$/\1 \2/' ;;
    #url)   printf '%s' 's/^.*| *\(http.*\)|\([0-9]*\)$/\1 \2/' ;;
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

    title="TITLE:$helperdir/bookmark-title.sh"
    tags="TAGS:$helperdir/bookmark-tags.sh"
    url="URL:$helperdir/bookmark-url.sh"
    all="/:$helperdir/bookmark-all.sh" # 'all' handled a bit differently 
    rofi -show '/' -modi "$all,$title,$url,$tags" -matching fuzzy

  # SEARCH_TYPE=<populator-type> $0
  # 2) Called by rofi 
  else
    awk <"$bookmarks" '
      {$0=$0""NR}        # append row number (to after the table last bar)
      /^\/\//{next}      # skip over C-like comments
      !/^[0-9]*$/{print} # skip blanks lines (awk added row number)
    ' |extract_entry_and_id "$SEARCH_TYPE"
  fi

# After a URL is entered
# Third step that determines the url from the id and then ask
elif printf '%s' "$*" | grep -q '^.\+ \+[0-9]\+$'; then
  id="$*"
  id="${id##*\ }"
  url="$(sed <"$bookmarks" "${id}q;d" | extract_entry_and_id url)"
  url="${url%\ *}"

  # Append the url to all the browser_tags to pass both to the fourth step
  "$promptbrowser" | awk '{$0=$0 "  \t'"$url"'"} {}1'

# $0 <browser_tag> <url>
# Last step that extracts the browser_tag of the prompt script and the url
# Does not push anything to stdout to close rofi
else
  args="$*"
  url=$(printf '%s' "$args" | awk '{print $2}') # select second and trim
  # TODO: Need to do something about this blocking rofi synchronously
  #       Crash when midori is first started 
  "$promptbrowser" "${args%%\ *}" "$url"
fi