#!/bin/sh

targeturl="$1"
browserchoice="$2"

save_to_clipboard() { printf '%s' "$1" | xclip -selection clipboard; }

# Here-document will do variable expansion
browserlist=$(grep ':' << EOF
  midori: midori
  epiphany: epiphany --private-instance --new-tab 
  firefox: firefox --new-tab 
  epiphany_incognito: epiphany --incognito-mode --new-tab 
  firefox_incognito: firefox --private-window
  clipboard: copy-to-clipboard.sh
  elinks
  lynx
  w3m
EOF
)
  #clipboard: save-to-clipboard.sh
  #clipboard: sh -c "printf '%s' \"\$1\" | xclip -selection clipboard"
  #clipboard: printf '%s' "$targeturl" | xclip -selection clipboard

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

# :!console %self
if [ -z "$*" ]; then
  printf '%s' "$browserlist" | sed 's/^ *\([^:]*\):.*$/\1/' 
else
  runbrowser=$(printf '%s' "$browserlist" \
    | grep "^ *$browserchoice:" \
    | sed 's/^[^:]*: *//')

  if [ -n "$runbrowser" ] && [ -n "$targeturl" ]; then
    nohup setsid sh -c "$runbrowser \"$targeturl\"" >/dev/null 2>&1 &
    #setsid $runbrowser "$targeturl" >/dev/null 2>&1 &
    #setsid nohup sh -c "$runbrowser \"$targeturl\"" >/dev/null 2>&1 &
    #setsid nohup $runbrowser "$targeturl" >/dev/null 2>&1 &
    #setsid nohup sh -c "$runbrowser \"$targeturl\"" & #>/dev/null 2>&1 &
    #sh -c "$runbrowser \"$targeturl\"" & #>/dev/null 2>&1 &
    #setsid nohup sh -c "exec $runbrowser \"$targeturl\"" & #>/dev/null 2>&1 &
  else
    exit 1
  fi
fi
