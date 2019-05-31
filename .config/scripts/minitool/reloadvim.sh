#!/usr/bin/env sh

name="$(basename "$0"; printf a)"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name}

DESCRIPTION
  
EOF
}

# TODO: Add option for ignore checks
skip="true"

main() {
  # TODO: Check if currently inside tmux session
  # TODO: Add tmux dependency checks
  # TODO: Make help not terrible
  # TODO: Add option for custom shell?
  tmux.sh test-inside-session || die 1 "FATAL: '${name}' -- Not in tmux session"
  "${skip}" || tmux.sh get-current-command | grep -q -e "^nvim" -e "^vim" \
    || tmux_die "Not running (n)vim at the moment"
  tmux send-keys Escape ":q" Enter

  # Need to sleep because vim eats the input stream while it closes
  # Wait until the current command is the interactive shell
  centiseconds=0
  "${skip}" || while [ "${centiseconds}" -lt 30 ]; do
    tmux.sh get-current-command | grep -q -e "bash$" -e "sh$" -e "dash$" \
      && break
    sleep 0.01
    centiseconds="$((centiseconds + 1))"
  done
  "${skip}" && sleep 0.1
  #tmux send-keys "$(tmux.sh get-current-command)"
  "${skip}" \
    || tmux.sh get-current-command | grep -q -e "bash$" -e "sh$" -e "dash$" \
    || tmux_die "Slow return to bash/sh/dash (>0.3 seconds)"

  tmux send-keys "${EDITOR} \"+normal! $1Gzt$2G$3|\" \"$4\"" Enter
}

tmux_die() {
  tmux display "$1"
  die 1 "FATAL" "$1"
}



# Helpers
puts() { printf %s\\n "$@"; }
die() { c="$1"; shift 1; for x in "$@"; do puts "$x" >&2; done; exit "$c"; }

main "$@"
