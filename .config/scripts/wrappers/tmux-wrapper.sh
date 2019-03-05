#!/usr/bin/env sh
  # $0 <cmd> [<PARAMETER1> [<PARAMETER2> ...]]
# Aggregate of various useful things things to do with tmux

show_help() {
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
    Prints a generic session to attach to if one is available or to a sane
    number to create new session for. See \`open\` for actual attaching
     
  i, insert PARAMETER
    Inserts the output of PARAMETER into the current pane by creating a
    temporary new window which executes
    
  o, open [PARAMETERS] (no working solution for PARAMETERS)
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
}

# Helpers
puts() { printf %s\\n "$@"; }
die() { printf %s\\n "$@" >&2; exit 1; }
is_inside_tmux() { test -z "${TMUX}"; }  # Tmux sets ${TMUX}

# Dependencies
command -v 'tmux' >/dev/null 2>&1 || die "FATAL: Requires \`tmux\`"

main() {
  cmd="$1"
  [ "$#" -gt "0" ] && shift 1
  done="false"
  case "${cmd}" in
    h|-h|help|--help)  show_help; exit 0 ;;
    g|get)     get_reasonable_generic_session_number; done="true" ;;
    i|insert)  insert_into_current_pane "$@"; done="true" ;;
    o|open)    run_in_generic "$@"; done="true" ;;
    p|prune)   prune_nongenerics; done="true" ;;
    s|split)   split_into_tmux_and_run "$@"; done="true" ;;
  esac
  "${done}" || { show_help; exit 1; }
}




# Usage: $0 
# Have to be careful of how quoting is done because it will essentialy eval
# The code at least once
insert_into_current_pane() {
  id="$(tmux run-shell "printf %s #{window_id}")"
  to_run="\"\$($*)\""
  tmux new-window "tmux send-keys -t '${id}' \"${to_run}\""
}

# Usage: $0
# The execution portion of tmux-get-free-generic.sh
#
# When tmux shows some wierd errors:
# https://www.mail-archive.com/dev@suckless.org/msg22465.html
# Open and run the command specified by the argument
run_in_generic() {
  tmux new-session -A -s "$(get_reasonable_generic_session_number)"
  #tmux send-keys "$*" Enter  # cannot send because new-session is blocking
}



# Usage: $0
# Kills all the sessions that are not named just numbers that are detached
# 'Named' is used to refer to non-generics
# 'Prune' means close anything not attached
#
# My vim+i3 setup creates a lot of <name><timestamp> tmux sessions that I might
# close without exiting, eg. {filename-sh1509934}
prune_nongenerics() {
  attached="a "
  detached="b "
  tmux list-sessions \
      -F "#{?session_attached,${attached},${detached}}#{session_name}" \
      2>/dev/null \
    | awk '/^'"${detached}"'[^0-9]+$/{ print($2); }' \
    | while IFS= read -r name; do
      tmux kill-session -t "${name}"
    done
}



# Usage: $0 [PARAMETER1] [PARAMETER2] ...
# Opens a new horizontal split and types <cmd...> ($*) and enters
# If not attached to a tmux session, then types <cmd...> into a new session
split_into_tmux_and_run() {
  pane_id=""
  # -d do not switch, -P print, -h horizontal, -F format of print
  if is_inside_tmux; then
    pane_id="$(tmux new-session -dP -F '#{pane_id}')"
  else
    pane_id="$(tmux split-window -dPh -F '#{pane_id}')"
  fi

  [ -n "$*" ] && tmux send-keys -t "$pane_id" "$*" Enter
}



# Usage: $0
# Enters a generic detached session or creates a new one with a sane number.
# 'Generic' means the default numbers-only session names. Starts from 0.
# Best used with `tmux new-session -A -s "$($0)"`
get_reasonable_generic_session_number() {
  attached="a "  # Space for awk to recognise new column
  detached="b "  # Space for awk to recognise new column
  # `tmux list-sessions` outputs to stderr if server not started yet
  generics_all="$(
    tmux list-sessions \
        -F "#{?session_attached,${attached},${detached}}#{session_name}" \
        2>/dev/null \
      | grep -e "^${detached}[0-9][0-9]*\$" -e "${attached}[0-9][0-9]*\$"
  )"

  # If there is a non-attached (NF == 1) generic to attach to, attach to it
  puts "${generics_all}" \
    | awk '/^$/{ next; } /^'"${detached}"'/{ print $2; exit 1; }';
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
