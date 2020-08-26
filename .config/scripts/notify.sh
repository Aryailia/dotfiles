#!/usr/bin/env sh

first="$( if [ "${1}" = "-" ]; then
    cat -
  else
    printf %s "${1}"
  fi
  printf a
)"; first="${first%a}"
shift 1  # ${first} eats the first argument

if [ -n "${DISPLAY}" ]; then
  notify-send "${first}" "$@"
elif [ -n "$TMUX" ]; then
  tmux display-message "${first}" "$@"
else
  printf %s "${first}" >&2
  printf \\n%s "$@" >&2
  exit 1
fi
