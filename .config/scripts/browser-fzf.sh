#!/usr/bin/env sh
  # CLI that gives an fzf UI to browser choice list
  # Will prompt the user for missing arguments

# Dependencies
promptbrowser="prompt-browser.sh"

# Arguments, prompt for missing arguments
 prompt="${1:-'Enter url'}"
    url="$2"; if [ -z "$url" ]; then printf '%s: ' "$prompt"; read -r url; fi
browser="${3:-$("$promptbrowser" \
  | fzf --no-sort --layout=reverse --prompt="$url | ")}"

#:!console %self "Enter url" "searx.me" "firefox"

# Might have to parse text to uri or whatever its called (unicode to percent)
# Do not need to null output
# Need setsid for use from i3, do not really understand why exactly,
# when other two fzf menus are fine
setsid "$promptbrowser" "$url" "$browser" >/dev/null 2>&1
