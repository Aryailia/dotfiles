#!/usr/bin/env sh

name="$(basename "$0"; printf a)"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name} [OPTION]

DESCRIPTION
  Tells \${EDITOR} (vim/neovim) to exit (via :q) and opens again at the same
  screen location and cursor position.

OPTIONS
  -i, --ignore-checks
    Ignore checking that we are inside a vim/nvim instance and arrive at a
    shell before proceeding to the next relevant steps
EOF
}



# TODO: Add option for custom shell check
main() {
  # Dependencies
  require 'tmux.sh' || die2 1 'FATAL' "'tmux.sh' not found in PATH"

  # Options processing
  args=''
  skip='false'
  for arg in "$@"; do case "${arg}" in
    -h|--help)  show_help; exit 0 ;;
    -i|--ignore-checks)  skip='true' ;;
    *)  args="${args} $(puts "${arg}" | eval_escape)"
  esac done

  eval "set -- ${args}"
  [ "$#" -lt "4" ] && { show_help; exit 1; }

  # Main
  tmux.sh test-inside-session || die2 1 'FATAL' 'Not in tmux session'
  #"${skip}" \
  #  || tmux.sh get-current-command | grep_for_shell \
  #  || tmux_die 'Not running (n)vim at the moment'
  tmux send-keys Escape ':q' Enter

  # Need to sleep because vim eats the input stream while it closes
  # Wait until the current command is the interactive shell
  # Hopefully our computers are fast enough for the wait here
  if "${skip}"; then
    sleep 0.1  # less interactive pause
  else
    time="$(date +%s%M)"  # %M milli, %s seconds since UNIX epoch
    while [ "$(($(date +%s%M) - time))" -lt 200 ]; do
      tmux.sh get-current-command | grep_for_shell && break
      sleep 0.01
    done
  fi
  # For debugging:
  #tmux send-keys "$(tmux.sh get-current-command)"

  "${skip}" \
    || tmux.sh get-current-command | grep_for_shell \
    || tmux_die 'Slow return to bash/sh/dash (>0.2 seconds)'

  # Add space to not include in ${HISTCONTROL} set to ignorespace
  tmux send-keys " ${EDITOR} \"+normal! $1Gzt$2G$3|\" \"$4\"" Enter
}

grep_for_shell() {
  <&0 grep -q -e '/bash$' -e '^bash$' \
    -e '/sh$' -e '^sh$' -e '/dash$' -e '^dash$'
}

tmux_die() {
  tmux display "$1"
  die2 1 "FATAL" "$1"
}



# Helpers
require() { command -v "$1" >/dev/null 2>&1; }
puts() { printf %s\\n "$@"; }
die2() { c="$1"; t="$2"; shift 2; puts "$t: '${name}'" "$@" >&2; exit "$c"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
