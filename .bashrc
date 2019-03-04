#!/usr/bin/env bash
  # Included shebang for shellcheck. Indent for autodetect indent
# TODO: Check if bashrc is for interactive sheelds and  where to declare things

# https://www.digitalocean.com/community/tutorials/how-to-use-bash-history-commands-and-expansions-on-a-linux-vps

#HISTFILESIZE=10000   # Number of commands to load to disk
#HISTSIZE=5000        # Portion of which, number of commands to load into memory
shopt -s histappend  # >> to history (not >), useful if opened mutiple sessions
PROMPT_COMMAND='b'

file="${HOME}/.config/aliasrc"; [ -f "${file}" ] && source "${file}"
alias rrc='source ~/.bash_profile'

b() {
  errorcode="$?"
  # More history syncing hackery (bash saves history once session closes)
  # TODO: Test history lines don't change with this (!51 to execute 51 command)
  # TODO: See https://unix.stackexchange.com/questions/1288/
  # TODO: BUG: when ${PWD} contains a newline (colors entire line)
  history -a  # Append command immediately to history
  history -c  # Clear current history for session
  history -r  # Read history back into memory
  PS1="$("${HOME}/.config/prompt.sh" "$errorcode" "$SECONDS")";
  SECONDS="0"
}

