#!/usr/bin/env sh
  # The list of browsers and how to execute

# Parameters
targeturl="$1"
browserchoice="$2"

# Here-document will do variable expansion
browserlist="$(grep ':' << EOF
  midori: midori
  epiphany: epiphany --private-instance --new-tab 
  firefox: firefox --new-tab 
  epiphany_incognito: epiphany --incognito-mode --new-tab 
  firefox_incognito: firefox --private-window
  clipboard: clipboard.sh --write
  elinks
  lynx
  w3m
EOF
)"

main() {
  if [ "$#" -le 1 ]; then
    p "${browserlist}" | sed 's/^ *\([^:]*\):.*$/\1/' 
    exit 1
  else
    #:!console %self http://www.github.com clipboard
    runbrowser="$(p "${browserlist}" \
      | awk '/^ *'"${browserchoice}"':/ { sub(/^[^:]*: */, "", $0); print $0; }'
    )"
    
    # Consider using nohup or tmux as well
    setsid ${runbrowser} "${targeturl}" >/dev/null 2>&1 &
  fi
}

p() { printf '%s' "$@"; }

# Midori sometimes does not open the url if not updated via NewTab... maybe
# run_midori() { midori -e TabNew && midori -e TabClose && midori "$*"; }

main "$@"
