#!/usr/bin/env sh
  # Managing number of stray sessions caused by running tmux on terminal startup
  # Resumes a defaultly named session if it is unattached
  # To use the print version do the following:
  # st -e $(resumerun-generic-session.sh)

p() { printf '%s' "$@"; }
puts() { printf '%s\n' "$@"; }

attached="(attached)"
generics="$(tmux list-sessions \
  -F '#{session_name} #{?session_attached,'"$attached"',}' \
  | grep '^[0-9]* '
)"

# If there is a non-attached (NF == 1) generic to attach to, attach to it
if p "${generics}" | grep -qv "$attached\$"; then
  session="$(p "${generics}" | awk '(NF == 1) { print $1; exit; }')"
  p "tmux attach-session -t ${session}" # Quoting ${session} causes problems
  #"$@" tmux attach-session -t "${session}"

# else find a sane number to make the new session
# Either generics are all attached or no sessions started at all
else
  # Consider all the `$generics`
  # -1 (+ 1 = 0) is what keeps the session count low
  session_name="$(puts '-1' "$generics" | awk -v Generics="$generics" '
    BEGIN {
      split(Generics, temp);
      for (i in temp) {
        if (temp[i] != "'"$attached"'") { Matched[temp[i]] = 1; }
      }
    }
    (1) { $1 = $1 + 1; }                # 
    (!Matched[$1]) { print $1; exit; }  # Print first non-existent session
  ')"
  # default to 0
  p "tmux new-session -s ${session_name:-0}"

  ## https://www.mail-archive.com/dev@suckless.org/msg22465.html
  ## Default to 0 if $filter is empty (thus skipping everything
  ## and returning an empty string)
  #"$@" tmux new-session -s "${session_name:-0}"
fi
