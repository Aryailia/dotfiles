#!/usr/bin/env sh

value='1'
if pgrep 'Xorg' >/dev/null 2>&1
  then notify-send "$@" && value="0"
  else [ -n "$TMUX" ] && tmux display-message "$@" && value="0"
fi
exit "${value}"
