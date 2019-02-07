#!/bin/sh
  # $0 <cmd...>
# Opens a new horizontal split and types <cmd...> ($*) and enters
# If not attached to a tmux session, then types <cmd...> into a new session

command -v 'tmux' >/dev/null 2>&1 || { echo 'ERROR: Requires `tmux`'; exit 1; }

# Test if inside tmux session. Tmux sets ${TMUX}
pane_id=""
if [ -z "${TMUX}" ]; then
  pane_id="$(tmux new-session -dP -F '#{pane_id}')"
else
  # -d does not change which pane is active, -P print, -h horizontal
  pane_id="$(tmux split-window -dPh -F '#{pane_id}')"
fi
tmux send-keys -t "$pane_id" "$*" Enter
