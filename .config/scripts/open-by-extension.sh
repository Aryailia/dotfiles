#!/usr/bin/env sh
  #

# Dependencies
browseropen="browser-fzf.sh"

url=$1
extension=$(printf '%s' "${url##*.}"  | awk '{print tolower($0)}')

match() {
  printf '%s' "$1" | grep -q "$2"
}

case "$extension" in
  png|jpg|jpeg) nohup setsid feh "$url" >/dev/null ;;
  mkv|mp4|gif|web) nohup setsid mpv -quiet "$url" >/dev/null ;;
  mp3|flac|opus|pdf) nohup setsid mpv -quiet "$url" >/dev/null ;; 
  *) "$browseropen" "${url}: " "$url"
esac

