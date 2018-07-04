#!/bin/sh

browserchoice="$1"
targeturl="$2"

browserlist=$(printf '
  midori:   run_midori
  firefox:  firefox -new-tab
  epiphany: epiphany
  elinks
  lynx
  w3m
' | grep ':') # Remove random spaces and the unimplemented browsers


# Create custom functions for running to avoid having to eval
# Have to be very careful about not blocking IO; rofi will freeze Xserver
# ===
# Midori someimtes will not open the url if it is not updated via NewTab etc
run_midori() {
  # Have to kill stdout (does not seem like have to kill stderr)
  midori -e TabNew >/dev/null && \
    midori -e TabClose >/dev/null && \
    midori "$*" >/dev/null &
}

if [ -z "$*" ]; then
  printf '%s' "$browserlist" | sed 's/^ *\([^:]*\):.*$/\1/' 
else
  runbrowser=$(printf '%s' "$browserlist" \
    | grep "^ *$browserchoice" \
    | sed 's/^[^:]*: *\(.*\)$/\1/')

  if [ -n "$runbrowser" ] && [ -n "$targeturl" ]; then
    #$(eval "$runbrowser $targeturl")
    "$runbrowser" "$targeturl"
  else
    exit 1
  fi
fi
