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
# 0) NOTE: May want to run this with: ASDF=0 $0
# 1) No arguments or pre-set variables inits rofi
# 2) ASDF is preset but no arguments, populates rofi depending on ASDF
# 3) Single bookmark: <data> <id>, ID is its line number in the file
#    
# 4) Has browser and 

# TODO: Fix commenting and documentation
# TODO: rofi menu include all the types (quickfix)
# TODO: Add to i3
# TODO: 

# Tightly-coupled-to-environment file location dependencies
scripts="$HOME/dotfiles/.config/scripts"
bookmarks="$HOME/ime/bookmarks.txt"
promptbrowser="$scripts/prompt-browser"

# Creates the intermediary files for parameter passing for rofi script mode
create_populator() {
  filename="$scripts/bookmark-$1.sh"
  content=$(printf '%s\n%s\n%s' \
    "#!/bin/sh" \
    "# please look to the rofi-prompt-bookmarks.sh for more" \
    "ASDF=$1 $0 \"\$*\"")

  # Save on a disk write if possible
  [ "$(cat "$filename")" != "$content" ] && printf '%s' "$content" > "$filename"
  chmod 744 "$filename"
  shellcheck "$filename"
}

extract_entry_andor_id() {
  case "$1" in
    # First rofi menu calls this part through populator, echos bookmarks
    # Tabular formating for my bookmarks
    # Digit at the end added by awk
    title) printf '%s' 's/^| *\(.*\)| *#.*|\([0-9]*\)$/\1 \2/' ;;
    tags)  printf '%s' 's/^.*| *\(#.*\)| *http.*| *\([0-9]*\)$/\1 \2/' ;;
    url)   printf '%s' 's/^.*| *\(http.*\)|\([0-9]*\)$/\1 \2/' ;;
  esac
}

# The state machine
# The state mode of Rofi works by calling the same script at each selection,
# with previous choice as the parameter. Any stdout will populate the menu
if [ -z "$*" ]; then
  # 1) Initial run, no arguments
  if [ -z "$ASDF" ]; then
    # Because cannot pass arguments to script mode rofi, have to create shell
    # script files that cal
    # haveCreate three files to basically call pass
    create_populator title
    create_populator tags
    create_populator url

    rofi -show url -modi 'url:bookmark-url.sh'

  # ASDF=<populator-type> $0
  # 2) Called by rofi 
  else
    awk <"$bookmarks" '
      {$0=$0""NR}        # append row number (to after the table last bar)
      /^\/\//{next}      # skip over C-like comments
      !/^[0-9]*$/{print} # skip blanks lines (awk added row number)
    ' |sed "$(extract_entry_andor_id "$ASDF")"
  fi

# After a URL is entered
# Third step that determines the url from the id and then ask
elif printf '%s' "$*" | grep -q '^.\+ \+[0-9]\+$'; then
  id="$*"
  id="${id##*\ }"
  url="$(sed <"$bookmarks" "${id}q;d" | sed "$(extract_entry_andor_id url)")"
  url="${url%\ *}"

  # Append the url to all the browser_tags to pass both to the fourth step
  "$promptbrowser" | awk '{$0=$0 "  \t'"$url"'"} {}1'

# $0 <browser_tag> <url>
# Last step that extracts the browser_tag of the prompt script and the url
# Does not push anything to stdout to close rofi
else
  args="$*"
  url=$(printf '%s' "$args" | awk '{print $2}') # select second and trim
  "$promptbrowser" "${args%%\ *}" "$url"
fi
exit 0


title='TITLE:bookmark-title.sh'
 tags='TAGS :bookmark-tags.sh'
  url='URL:bookmark-url.sh'

  choice=$(rofi -show 'URL' -modi "$url" -matching 'fuzzy')
  #-config $HOME/.config/rofi/config
  #rofi -show keys
# choice="$(rofi -show combi -combi-modi "$tags,$title,$url" \
#   -modi "combi,$title,$url,$tags" -matching fuzzy)"
[ -z $choice ] && exit 1
