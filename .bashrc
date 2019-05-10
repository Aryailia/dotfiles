#!/usr/bin/env bash
  # Included shebang for shellcheck. Indent for autodetect indent
# For interactive+login shells and subprocesses

stty -ixon       # Disable Ctrl-S and Ctrl-Q
#shopt -s autocd  # cd without typing cd just typing name. Conflicts too much

# https://www.digitalocean.com/community/tutorials/how-to-use-bash-history-commands-and-expansions-on-a-linux-vps

#HISTFILESIZE=10000   # Number of commands to load to disk
#HISTSIZE=5000        # Portion of which, number of commands to load into memory
shopt -s histappend  # History is added

PROMPT_COMMAND="$(<<EOF cat -
  errorcode="\$?"
  # More history syncing hackery (bash saves history once session closes)
  # TODO: Test history lines don't change with this (!51 to execute 51 command)
  # TODO: See https://unix.stackexchange.com/questions/1288/
  # TODO: BUG: when ${PWD} contains a newline (colors entire line)
  history -a  # Append command immediately to history
  history -c  # Clear current history for session
  history -r  # Read history back into memory
  PS1="\$("${HOME}/.config/prompt.sh" "\$errorcode" "\$SECONDS" "\$!")"
  SECONDS="0"
EOF
)"

[ -f "${HOME}/.config/aliasrc" ] && source "${HOME}/.config/aliasrc"
alias rrc='source ~/.bashrc; source ~/.config/shell_profile'

#c() {
#  if [ -z "$1" ]; then
#    "${SCRIPTS}/namedpath.sh" --list-aliases
#  else
#    path="$("${SCRIPTS}/namedpath.sh" "$1"; printf x)"; path="${path%?}"
#    cd "${path}" && la  # ls with some options, defined in alias
#  fi
#}

cd-of() {
  temp="$("$@"; err="$?"; printf x; exit "${err}")" || return "$?"
  temp="${temp%x}"
  cd "${temp}"
}
