#!/usr/bin/env sh
  # 
# Aggregate of various useful things things to do with tmux

show_help_and_exit() {
  name="$(basename "$0"; printf a)"; name="${name%??}"
  <<EOF cat - >&2
SYNOPSIS
  ${name} COMMAND [PARAMETER1] [PARAMETER2] ...
  
DESCRIPTION
  Just a wrapper around all the tmux functions that work for my workflow.
  My workflow is that a new session is created whenever a new window is opened
  in the window manager

COMMANDS
  h, -h, help, --help
    Displays this help menu
 
  g, get
    Primarly for use by open
    
  o, open
    Replacement running \`tmux\` to enter a tmux session. Has a keep the session
    count reasonable feature. \`tmux send-keys\` all the PARAMETERS and enters.
    
  p, prune
    Due to my preview function in vim creating lots of sessions. Kill all those
    sessions if closing them without exiting.

  s, split [PARAMETERS]
    Either opens into a new pane by splitting the current window or opens into
    a new tmux session when not currently inside a tmux session. Does not take
    advantage of the reasonable session count to avoid splitting random sessions
    that are not even visible. \`tmux send-keys\` all the PARAMETERS and enters.
  
EOF
  exit 1
}

# Helpers
puts() { printf %s\\n "$@"; }
die() { printf %s\\n "$@" >&2; exit 1; }

# Dependencies
command -v 'tmux' >/dev/null 2>&1 || die 'FATAL: Requires `tmux`'

main() {
  cmd="$1"
  [ "$#" -gt "0" ] && shift 1
  case "${cmd}" in
    h|-h|help|--help)  show_help_and_exit ;;
    g|get)    get_reasonable_generic_session_number; exit 0 ;;
    o|open)   run_in_generic "$@"; exit 0 ;;
    p|prune)  prune_nongenerics; exit 0 ;;
    s|split)  split_into_tmux_and_run "$@"; exit 0 ;;
  esac
  show_help_and_exit
}

# $0 <cmd_to_run_arg1> <cmd_to_run_arg2> ...
# The execution portion of tmux-get-free-generic.sh
# Sends the command all as keyboard events, so will be displayed twice
#
# When tmux shows some wierd errors:
# https://www.mail-archive.com/dev@suckless.org/msg22465.html
# Open and run the command specified by the argument
run_in_generic() {
  asdf="$(get_reasonable_generic_session_number)"
  tmux new-session -A -s "${asdf}"
  #tmux send-keys "$*" Enter  # cannot send because tmux blocks
}


# Opens a new horizontal split and types <cmd...> ($*) and enters
# If not attached to a tmux session, then types <cmd...> into a new session
split_into_tmux_and_run() {
  # Test if inside tmux session. Tmux sets ${TMUX}
  pane_id=""
  if [ -z "${TMUX}" ]; then
    pane_id="$(tmux new-session -dP -F '#{pane_id}')"
  else
    # -d does not change which pane is active, -P print, -h horizontal
    pane_id="$(tmux split-window -dPh -F '#{pane_id}')"
  fi
  tmux send-keys -t "$pane_id" "$*" Enter
}



# Kills all the sessions that are not named just numbers that are detached
# 'Named' is used to refer to non-generics
# 'Prune' means kill anything not attached
#
# My setup creates a lot of <name><timestamp> tmux sessions that I might close
# without exiting, eg. {filename-sh1509934}
prune_nongenerics() {
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
}





# Resumes a defaultly named session if it is unattached, creates a new session
# with the lowest possible non-negative number. Manages number creep.
# 'Free' used to means detached (deemed useless) or lowest, unused by an
# attached tmux session, non-negative number.
#
# Tmux by default starts from 0. Intended for use with `tmux new-session -A`.
# See `tmux-get-free-generic.sh` for example.
get_reasonable_generic_session_number() {
  attached="a " 
  generics_all="$(
    tmux list-sessions -F "#{?session_attached,${attached},}#{session_name}" \
      2>/dev/null  \
    | grep -e '^[0-9][0-9]*$' -e "${attached}[0-9][0-9]*\$"
  )"

  # If there is a non-attached (NF == 1) generic to attach to, attach to it
  puts "${generics_all}" \
    | awk '/^$/{ next; } !/^'"${attached}"'/{ print $1; exit 1; }';
  errorcode="$?"  # It errors 1 on finding a detached

  if [ "${errorcode}" = "0" ]; then
    attached_generics="${generics_all}"
    mark="--"
    puts "${attached_generics}" "${mark}" "_ -1" "${attached_generics}" | awk '
      /^'"${mark}"'$/ { halfway = 1; next; }
      (!halfway) { matched[$2] = 1; }
      (halfway && !matched[$2 + 1]) { print($2 + 1); exit; }
    '
  fi
}

main "$@"
