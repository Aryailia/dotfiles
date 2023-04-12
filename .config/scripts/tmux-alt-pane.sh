#!/bin/sh

second_pane() {
  current_pane_id="$( tmux display-message -pF '#{pane_id}' )"
  for id in $( tmux list-panes -F "#{pane_id}" ); do
    [ "${id}" = "${current_pane_id}" ] && continue
    printf %s\\n "${id}"
    return 0
  done
}

[ "$#" -lt 1 ] && { printf %s\\n "Specify a tmux command"; exit 1; }
[ -z "${TMUX}" ] && { printf %s\\n "Not in tmux session"; exit 1; }
command="${1}"; shift 1 || exit "$?"

pane_id="$( second_pane )"
[ -z "${pane_id}" ] && pane_id="$( tmux split-window -dhPF "#{pane_id}" )"
tmux "${command}" -t "${pane_id}" "$@"
