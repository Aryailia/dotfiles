#!/usr/bin/env sh

# Dependencies
browseropen="browser-fzf.sh"

url=$1
extension=${url##*.}

match() {
  printf '%s' "$1" | grep -q "$2"
}

if match "$extension" 'png\|jpg\|jpeg'; then
  nohup setsid feh "$url" >/dev/null
elif match "$extension" 'mkv\|mp4\|gif\|web'; then
  nohup setsid mpv -quiet "$url" >/dev/null
elif match "$extension" 'mp3\|flac\|opus\|pdf'; then
  nohup setsid mpv -quiet "$url" >/dev/null
else
  "$browseropen" "${url}: " "$url"
fi

