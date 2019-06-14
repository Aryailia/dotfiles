#!/usr/bin/env sh

value='1'
pgrep 'Xorg' >/dev/null 2>&1 && notify-send "$@" && value="0"
[ -n "$TMUX" ] && tmux display-message "$@" && value="0"
exit "${value}"
