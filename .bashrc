#!/usr/bin/env bash
  # Included shebang for shellcheck. Indent for autodetect indent
# TODO: Check if bashrc is for interactive sheelds and  where to declare things

# https://www.digitalocean.com/community/tutorials/how-to-use-bash-history-commands-and-expansions-on-a-linux-vps

#HISTFILESIZE=10000   # Number of commands to load to disk
#HISTSIZE=5000        # Portion of which, number of commands to load into memory
shopt -s histappend  # >> to history not > (for mutiple sessions)

PROMPT_COMMAND="$(<<EOF cat -
  errorcode="\$?"
  # More history syncing hackery (bash saves history once session closes)
  # TODO: Test history lines don't change with this (!51 to execute 51 command)
  # TODO: See https://unix.stackexchange.com/questions/1288/
  # TODO: BUG: when ${PWD} contains a newline (colors entire line)
  history -a  # Append command immediately to history
  history -c  # Clear current history for session
  history -r  # Read history back into memory
  eval 'PS1="\$("${HOME}/.config/prompt.sh" "\$errorcode" "\$SECONDS")";'
  SECONDS="0"
EOF
)"

[ -f "${HOME}/.config/aliasrc" ] && source "${HOME}/.config/aliasrc"
alias rrc='source ~/.bash_profile'

c() {
  if [ -z "$1" ]; then
    "${SCRIPTS}/namedpath.sh" --list-aliases
  else
    path="$("${SCRIPTS}/namedpath.sh" "$1"; printf x)"; path="${path%?}"
    cd "${path}" && ls -Ah --group-directories-first --color=auto
  fi
}

