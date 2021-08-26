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

  i, insert-evaluate PARAMETER
    Inserts the output of PARAMETER into the current pane by creating a
    temporary new window which executes

  ls, list-sessions [PARAMETERS]
    Just a clone of tmux list-sessions

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

  r, run-in-new-window [COMMAND_TO_RUN [ARG1 [ARG2 ...]]]
    Runs COMMAND_TO_RUN and its ARG1, ARG2 ... in a new window (good for
    interactive scripts like fzf), saves the output to a temp tmux buffer,
    waits for that to finish, prints that buffer to STDOUT for the original
    window, and deletes the temp buffer.

  wt, write-to-temp [COMMAND_TO_RUN [ARG1 [ARG2 ...]]]
  pt, rt, pop-from-temp

  test-inside-session
  get-current-command
  get-current-pid
ENVIRONMENT
  SHELL
    The shell to use for the tmux session. Usually already set
EOF
}

# Helpers
puts() { printf %s\\n "$@"; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }
is_inside_tmux() { test -n "${TMUX}"; }  # Tmux sets ${TMUX}
require() { command -v "$1" >/dev/null 2>&1; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }




main() {
  # Dependencies
  require 'tmux' || die FATAL 1 " Requires \`tmux\`"
  # Tmux runs with login shell which sources .bashrc twice (initial login
  # and tmux session started). Running the shell as `tmux new-session`
  # makes it non-login.
  # Not sure if adding `exec` here helps or hurts
  [ -x "${SHELL}" ] || SHELL="$(
    if require getent && require logname  && logname >/dev/null 2>&1
      then getent passwd "$(logname)" | cut -d ':' -f 7  # get default shell
      else command -v bash
    fi
  )"

  # Main
  cmd="$1"
  [ "$#" -gt "0" ] && shift 1
  case "${cmd}"
    in h|-h|help|--help)     show_help
    ;; g|get)                get_next_session true
    ;; i|insert-evaluate)    insert_into_current_pane "$@"
    ;; ls|list-sessions)     tmux list-sessions "$@"
    ;; o|open)               run_in_generic "$@"
    ;; p|prune)              prune_nongenerics
    ;; r|run-in-new-window)  run_in_new_window "$@"
    ;; s|split)              split_into_tmux_and_run "$@"
    ;; pt|rt|pop-from-temp)  tmux show-buffer -b temp; tmux delete-buffer -b temp
    ;; wt|write-to-temp)     "$@" | tmux load-buffer -b temp -
    ;; test-inside-session)  is_inside_tmux
    ;; get-current-command)  get_current_command
    ;; get-current-pid)      get_current_pid
    ;; *)  show_help; exit 1
  esac
}



# Usage: $0
# Have to be careful of how quoting is done because it will essentialy eval
# The code at least once
# Eg. `tmux.sh insert echo yo` inside a tmux session yields 'yo'
insert_into_current_pane() {
  is_inside_tmux || die FATAL 1 'You are not within a tmux session'
  id="$(tmux display-message -p "#{pane_id}")"
  cmd="\$(env TARGET_PANE="${id}" $*)"  # Passing a literal $( )
  tmux new-window "tmux send-keys -t '${id}' \"${cmd}\""
}



# This is useful for running interactive scripts from inside `vim`
# Runs "$@" in new-window (so we can use interactive scripts)
# Alternatively you could read from '/dev/tty' depending on the use case
# Transfers to original window via 'temp' buffer
run_in_new_window() {
  is_inside_tmux || die FATAL 1 'You are not within tmux session'
  cmd=""
  for arg in "$@"; do
    cmd="${cmd}$( printf %s\\n "${arg}" | eval_escape ) "
  done

  tmux new-window "tmux.sh write-to-temp ${cmd}; tmux wait -S ping"
  tmux wait ping
  tmux.sh pop-from-temp
}




# Usage: $0
# The execution portion of tmux-get-free-generic.sh
#
# When tmux shows some wierd errors:
# https://www.mail-archive.com/dev@suckless.org/msg22465.html
# Open and run the command specified by the argument
run_in_generic() {
  if [ -z "$*" ]
    # Using "${SHELL}" makes this not do a double open for some reason
    then exec tmux new-session -A -s "$(get_next_session true)" "${SHELL}"
    else exec tmux new-session -s "$(get_next_session true)" "$*"
  fi
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
  # -d do not switch, -P print, -h horizontal, -F print format, -s session name
  if ! is_inside_tmux; then
    pane_id="$(tmux new-session -dPA -F '#{pane_id}' \
      -s "$(get_next_session false)" "${SHELL}")"
  else
    pane_id="$(tmux split-window -dPh -F '#{pane_id}' "${SHELL}")"
  fi

  [ -n "$*" ] && tmux send-keys -t "$pane_id" "$*" Enter
}



# Usage: $0
# Enters a generic detached session or creates a new one with a sane number.
# 'Generic' means the default numbers-only session names. Starts from 0.
# Best used with `tmux new-session -A -s "$($0)"`
# $1 - true if wanting to check detached
get_next_session() {
  check_detached="$1"

  attached="a "  # Space for awk to recognise new column
  detached="b "  # Space for awk to recognise new column
  # 2>/dev/null since `tmux list-sessions` outputs if server not started yet
  generics="$(
    tmux list-sessions \
        -F "#{?session_attached,${attached},${detached}}#{session_name}" \
        2>/dev/null \
      | grep -e "^${detached}[0-9][0-9]*\$" -e "${attached}[0-9][0-9]*\$"
  )"

  # If searching for non-attached generic and one exists, attach to it
  if  "${check_detached}" \
      && ! puts "${generics}" | awk "/^${detached}/{ print \$2; exit 1; }"
    then :     # Do nothing. It errors 1 on finding a detached
  # Otherwise find a reasonable number
  else         # This means all sessions in ${generics} are attached (logic)
    mark="--"  # Need to mark since going to double process ${generics}
    puts "${generics}" "${mark}" "_ -1" "${generics}" | awk '
      /^'"${mark}"'$/ { halfway = 1; next; }
      (!halfway) { matched[$2] = 1; }  # First pass build array
      (halfway && !matched[$2 + 1]) { print($2 + 1); exit; }
    '
  fi
}



# This should be run from an setsid or from the .tmux.config file (I think)
get_current_command() {
  if [ "$#" -gt 0 ]; then
    tmux display-message -p '#{pane_current_command}' -t "$1"
  else
    tmux display-message -p '#{pane_current_command}'
  fi
  # Busybox -a seems to be the same as -l, -n newest, -s SID
  #pgrep -nls "$(tmux display-message -p "#{pane_pid}")" \
  #  | awk '{ sub(/^[0-9]* /, ""); a = $0; } END{ printf("%s", a); }'
  ## -n newest, -a PID and full command, -t terminal
  #pgrep -n -l -t "$(tmux display-message -p "#{pane_tty}" | sed 's|/dev/||')" \
    #| awk '{ sub(/^[0-9]* /, ""); a=$0; } END{ printf("%s", a); }'
}

get_current_pid() {
  pgrep -nls "$(tmux display-message -p "#{pane_pid}")" \
    | awk '{ a = $1; } END{ printf("%s", a); }'
}

main "$@"
