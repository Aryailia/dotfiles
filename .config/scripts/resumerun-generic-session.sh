#!/usr/bin/env sh
# Managing number of stray sessions caused by running tmux on terminal startup
# Resumes a defaultly named session if it is unattached

p() { printf '%s' "$@"; }
put() { printf '%s\n' "$@"; }
session_name() { p "$1" | sed 's/^\([^:]*\):.*$/\1/'; }

# Number only sessions that are not attached
generics="$(tmux list-sessions | grep '^[[:digit:]]*:')"

###
# If there is a free generic to attach to, attach to it
free_generics="$(p "$generics" | grep -v '(attached)$')"
if [ -n "$free_generics" ]; then
  "$@" tmux attach-session -t "$(p "$free_generics" \
    | head --lines=1 \
    | session_name
  )"
###
# else find a sane number to make the new session
else
  # Generate two 'arrays', the ids and the futureIds=(0, id[0]+1, ...ids[i]+1)
  # add 0 to list of considered ids, this is the only reducing mechanism
  #
  # Get the string of newline seperated session names of the generic sessions
  genericIds="$(session_name "$generics")"

  # First array: join genericIds list with '|' as the deliminter
  filter="$(p "$genericIds" | paste --serial --delimiters '|')"

  # Second array: Prepends "-1\n" to the genericIds list and increments one
  # This '-1' is so that we consider session 0 as a name (after incrementing)
  next_id="$(put '-1' "$genericIds" | awk '
    { $1 = $1 + 1; }        # increment each line
    /'"$filter"'/{ next; }  # remove if already the name of an active session
    !i++{ min = $1; }       # only runs on first valid; initialise min to that
    { min = (min < $1) ? min : $1; }
    END{ print min; }
  ')"
  
  # If running 'st -e' (simple terminal), error errsec 1005 is safe to ignore
  # https://www.mail-archive.com/dev@suckless.org/msg22465.html
  # Default to 0 if $filter is empty (thus skipping everything
  # and returning an empty string)
  "$@" tmux new-session -s "${next_id:-0}"
fi
