#!/bin/sh
  # No parameters
# Resumes a defaultly named session if it is unattached, creates a new session
# with the lowest possible non-negative number. Manages number creep.
# 'Free' used to means detached (deemed useless) or lowest, unused by an
# attached tmux session, non-negative number.
#
# Tmux by default starts from 0. Intended for use with `tmux new-session -A`.
# See `tmux-get-free-generic.sh` for example.

# Helpers
p() { printf '%s' "$@"; }
puts() { printf '%s\n' "$@"; }

# Dependencies
command -v 'tmux' >/dev/null 2>&1 || { echo 'FATAL: Requires `tmux`'; exit 1; }

# Main
# Unnecessary to use this long a name but mimics the original format
attached="(attached)" 
generics="$(tmux 2>/dev/null list-sessions \
  -F '#{session_name} #{?session_attached,'"${attached}"',}' \
  | grep '^[0-9]* '
)"

# If there is a non-attached (NF == 1) generic to attach to, attach to it
if p "${generics}" | grep -qv "${attached}\$"; then
  p "${generics}" | awk '(NF == 1) { print $1; exit; }'

# else find a sane number to make the new session
else
  # Consider all the `${generics}`, defaults to 0
  # -1 (+ 1 = 0) is what keeps the session count low
  puts '-1' "${generics}" | awk -v Generics="${generics}" '
    BEGIN {
      split(Generics, temp);
      for (i in temp) {
        if (temp[i] != "'"${attached}"'") { Matched[temp[i]] = 1; }
      }
    }
    (1) { $1 = $1 + 1; }                # 
    (!Matched[$1]) { print $1; exit; }  # Print first non-existent session
  '
fi
