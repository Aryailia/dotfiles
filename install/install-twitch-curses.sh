#!/bin/sh
temp=/tmp/
cd "$temp" || exit


dependencies="python3-curl streamlink"
if [ ! -d twitch-curses ]; then
  git clone https://gitlab.com/corbie/twitch-curses
fi
for package in $dependencies; do
  [ -z "$(xbps-query "$package")" ] && xbps-install "$package"
done

sudo install -Dm755 twitch-curses/twitch-curses.py "/usr/bin/twitch-curses"
