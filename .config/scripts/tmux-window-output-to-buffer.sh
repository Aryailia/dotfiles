#!/bin/sh

eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
cmd="$( for arg in "$@"; do
  printf ' '
  printf %s "${arg}" | eval_escape
done )"
# Use both as channel and buffer name
uid="output-for-$( tmux display-message -p '#{pane_id}' )"

tmux delete-buffer -b "${uid}" 2>/dev/null
tmux new-window "${cmd} | tmux load-buffer -b '${uid}' -; tmux wait-for -S '${uid}'"
tmux wait-for "${uid}"
[ -n "$( tmux list-buffer -f "#{m:#{buffer_name},${uid}}" )" ] && tmux show-buffer -b "${uid}"
tmux delete-buffer -b "${uid}" 2>/dev/null
