#!/bin/sh
temp=/tmp/
cd "$temp"

dependencies="python3-curl"
[ ! -d twitch-curses ] && git clone https://gitlab.com/corbie/twitch-curses
target="/usr/bin/twitch-curses"
for package in $dependencies; do
  [ -z "$(xbps-query "$package")" ] && xbps-install "$package"
done

sudo install -Dm755 twitch-curses/twitch-curses.py "/usr/bin/twitch-curses"
