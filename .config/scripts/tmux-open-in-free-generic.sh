#!/usr/bin/env sh
  # $0 <cmd_to_run_arg1> <cmd_to_run_arg2> ...
# The execution portion of tmux-get-free-generic.sh
# Sends the command all as keyboard events, so will be displayed twice
#
# When tmux shows some wierd errors:
# https://www.mail-archive.com/dev@suckless.org/msg22465.html

# Dependencies
getid="${SCRIPTS}/wrappers/tmux-get-free-generic.sh"
[ -x "${getid}" ] || { "${getid} must exit and be executable"; exit 1; }
session_name="$(${getid})" || exit 1

# Main
# Open and run the command specified by the argument
tmux new-session -A -s "${session_name}"
tmux send-keys "$*" Enter
