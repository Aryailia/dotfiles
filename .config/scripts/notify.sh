#!/usr/bin/env sh

value='1'
first="$( if [ "${1}" = "-" ]; then
    cat -
  else
    printf %s\\n "${1}"
  fi
  printf a
)"; first="${first%?a}"
shift 1

if pgrep 'Xorg' >/dev/null 2>&1
  then notify-send "${first}" "$@" && value="0"
  else [ -n "$TMUX" ] && tmux display-message "$@" && value="0"
fi
exit "${value}"
