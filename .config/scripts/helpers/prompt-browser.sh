#!/bin/sh

targeturl="$1"
browserchoice="$2"

save_to_clipboard() { printf '%s' "$1" | xclip -selection clipboard; }

browserlist=$(grep ':' << EOF
  midori: run_midori
  epiphany: run_epiphany
  firefox: run_firefox 
  epiphany_incognito: run_epiphany_incognito
  firefox_incognito: run_firefox_incognito
  clipboard: save_to_clipboard
  elinks
  lynx
  w3m
EOF
)

# Create custom functions for running to avoid having to eval
# Have to be very careful about not blocking IO; rofi will freeze Xserver
# Seems like both browser itself has be backgrounded, and can just redirect
# the greater function, but have to redirect both stdout and stderr
# ===
# Midori sometimes does not open the url if not updated via NewTab... maybe
run_midori() { midori "$1" & }
#run_midori() { midori -e TabNew && midori -e TabClose && midori "$*" & }
run_firefox() { firefox --new-tab "$1" & }
run_epiphany() { epiphany --new-tab "$1" --private-instance & }
run_epiphany_incognito() { epiphany --new-tab "$1" --incognito-mode & }
run_firefox_incognito() { firefox --private-window "$1" & }

if [ -z "$*" ]; then
  printf '%s' "$browserlist" | sed 's/^ *\([^:]*\):.*$/\1/' 
else
  runbrowser=$(printf '%s' "$browserlist" \
    | grep "^ *$browserchoice:" \
    | sed 's/^[^:]*:\s*\(\S*\)\s*$/\1/')

  if [ -n "$runbrowser" ] && [ -n "$targeturl" ]; then
    #$(eval "$runbrowser $targeturl")
    "$runbrowser" "$targeturl" >/dev/null 2>&1
  else
    exit 1
  fi
fi
