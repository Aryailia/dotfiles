#!/usr/bin/env sh
# 
# Relocate $0 for dependency for build macro
  # :!console %self

# Dependencies
promptbrowser="$(dirname "$0")/helpers/prompt-browser.sh"

# Arguments
 prompt=${1:-'Enter url'}
    url=$2; if [ -z "$url" ]; then printf '%s: ' "$prompt"; read -r url; fi
browser=${3:-$("$promptbrowser" \
  | fzf --no-sort --layout=reverse --prompt="$url | ")}

# Might have to parse text to uri or whatever its called (unicode to percent)
nohup setsid "$promptbrowser" "$url" "$browser" >/dev/null 2>&1 #&
