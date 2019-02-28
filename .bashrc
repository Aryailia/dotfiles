#!/usr/bin/env bash
  # Included shebang for shellcheck. Indent for autodetect indent
# TODO: Check if bashrc is for interactive sheelds and  where to declare things

# https://www.digitalocean.com/community/tutorials/how-to-use-bash-history-commands-and-expansions-on-a-linux-vps

#PS1='[\u@\h \W]\$ ' # default PS1
#HISTFILESIZE=10000   # Number of commands to load to disk
#HISTSIZE=5000        # Portion of which, number of commands to load into memory
shopt -s histappend  # >> to history (not >), useful if opened mutiple sessions
PROMPT_COMMAND='b'

alias rrc='source ~/.bash_profile'

# Do not execute `lx` if `cd` errors
c() {
  if [ -z "$1" ]; then
    namedpath --list-aliases
    return 1
  else
    path="$(namedpath "$1"; printf 'x')"; path="${path%?}"
    cd "${path}" && lx .
  fi
}
b() {
  errorcode="$?"
  # More history syncing hackery (bash saves history once session closes)
  # TODO: Test history lines don't change with this (!51 to execute 51 command)
  # TODO: See https://unix.stackexchange.com/questions/1288/
  # TODO: BUG: when ${PWD} contains a newline (colors entire line)
  history -a  # Append command immediately to history
  history -c  # Clear current history for session
  history -r  # Read history back into memory
  PS1="$(~/.config/prompt.sh "$errorcode" "$SECONDS")";
  SECONDS="0"
}

