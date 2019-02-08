#!/usr/bin/env sh
  # No arguments
# Kills all the sessions that are not named just numbers that are detached
# 'Named' is used to refer to non-generics
# 'Prune' means kill anything not attached
#
# My setup creates a lot of <name><timestamp> tmux sessions that I might close
# without exiting, eg. {filename-sh1509934}
nongeneric_session_list="$(tmux list-sessions | awk '
  !/^[0-9]*:|attached/ {
    gsub(/:.*/, "", $0);
    print $0;
  }
')"

# Add a newline or read might not read it
printf '%s\n' "$nongeneric_session_list" | while IFS= read -r name; do
  tmux kill-session -t "$name"
done
