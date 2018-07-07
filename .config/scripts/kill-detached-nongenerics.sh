#!/usr/bin/env sh
# Kills all the sessions that are not named just numbers that are detached
# My setup creates a lot of <name><timestamp> tmux sessions that I might close
# without exiting, eg. {filename-sh1509934}
nongeneric_session_list=$(tmux list-sessions \
  | grep --invert-match '^[0-9]*:\|(attached)$' \
  | sed 's/:.*//'
)
# Add a newline or read might not read it
printf '%s\n' "$nongeneric_session_list" | while IFS= read -r name; do
  tmux kill-session -t "$name"
done
