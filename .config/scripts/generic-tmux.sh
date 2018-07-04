#!/bin/sh
# Managing number of stray sessions caused by running tmux on terminal startup
# Resumes a defaultly named session if it is unattached

# pass the terminal with its exection
run=$1

# Number only sessions that are not attached
generics="$(tmux list-sessions |  grep '^[[:digit:]]*:')"
free_generics="$(printf '%s\n' "$generics" | grep --invert-match '(attached)$')"

# If there is a free generic to attach to, attach to it
if [ -n "$free_generics" ]; then
  first_generic=$(echo "$free_generics" | head -n 1 | sed 's/\:.*//')
  $run tmux attach-session -t "$first_generic"

# else find a sane number to make the new session
else
  # two 'arrays', the ids and the futureIds=(0, id[0]+1, ...ids[i]+1)
  # add 0 to list of considered ids, this is the only reducing mechanism
  genericIds="$(printf '%s\n' "$generics" | sed 's/\:.*//')"
  futureIds="$(printf '%s\n' '-1' "$genericIds" | awk '{$1=$1+1}1')"
  filter="$(printf '%s\n' "$genericIds" | paste -sd '|')"

  # apply $filter to since those sessions already exist
  next_id="$(printf '%s\n' "$futureIds" \
    | awk "/$filter/{next}1" \
    | awk '!i++{ min = $1 } { min = (min<$1) ? min : $1 } END{ printf min }')"

  # default to 0 if $filter is empty
  $run tmux new-session -s "${next_id:-0}"
fi
