#!/usr/bin/env sh
# !console %self
# :!console %self 'https://searx.me/'

# Dependencies
promptbrowser="$(dirname "$0")/helpers/prompt-browser.sh"

# Argumnets
    url="${1:-$(rofi -dmenu -p 'url')}"
browser="${2:-$("$promptbrowser" | rofi -dmenu -p 'browser')}"

# Run
"$promptbrowser" "$url" "$browser"
