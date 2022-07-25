#!/bin/sh

pid="$( tmux display-message -p "#{pane_id}" )"

tmux new-window '
  cd "${PASSWORD_STORE_DIR}" || exit "$?"
  find ./* -type f \
    | sed "s!^\./!!; s!\.gpg\$!!" \
    | fzf \
    | tmux load-buffer -b temp -
  #pass show "$( tmux save-buffer -b temp - )" | clipboard.sh -w
  #sleep 1
  #notify.sh "📋"
  pass show "$( tmux save-buffer -b temp - )" | tmux load-buffer -b temp -
  tmux paste-buffer -b temp -s "" -t "'"${pid}"'"
  tmux delete-buffer -b temp
'
