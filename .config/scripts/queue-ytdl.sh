#!/usr/bin/sh

destination="~/storage/downloads/queue/"

which 'youtube-dl' >/dev/null || { echo 'youtube-dl not found'; exit 1; }
[ -e "$destination" ] && { echo "$destination not found"; exit 1; }

bestfreevideo='bestvideo[ext=webm]'
bestfreeaudio='bestaudio[ext=webm]'
webm360p='243'
limit480p='bestvideo[height<=480]'
freelimit480p='bestvideo[height<=480][ext=webm]'

format="$webm360p+$bestfreeaudio"
format="$format/$freelimit480p+bestaudio"
format="$format/$webm360p+bestaudio"
format="$format/$bestfreevideo+$bestfreeaudio"
format="$format/$limit480p+$bestfreeaudio"
format="$format/best"

ts youtube-dl --add-metadata -ic -f "$format" \
  -o "$destination/%(title)s-%(id)s.%(ext)s" "$*"
