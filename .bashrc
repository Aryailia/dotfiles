#!/usr/bin/env bash
  # Included shebang for shellcheck. Indent for autodetect indent
# For interactive+login shells and subprocesses

stty -ixon       # Disable Ctrl-S and Ctrl-Q
#shopt -s autocd  # cd without typing cd just typing name. Conflicts too much


# History modification, https://sanctum.geek.nz/arabesque/better-bash-history
HISTFILESIZE=10000             # Commands to save to disk (default 500)
HISTSIZE="${HISTFILESIZE}"     # Portion of which to load into memory
HISTTIMEFORMAT='%F %T '        # Format to record time executed
HISTCONTROL='ignoreboth'       # 'ignoreboth' is the following:
                               # - 'ignorespace': commands preceded by spaces
                               # - 'ignoredups':  squash uninterrupted repeats
HISTIGNORE='ls:bg:fg:history'  # Do not log these commands
shopt -s histappend            # History is added
#shopt -s cmdhist               # Join multi-line commands onto a single line

# Do not log these commands

PROMPT_COMMAND="$(<<EOF cat -
  errorcode="\$?"
  # More history syncing hackery (bash saves history once session closes)
  # TODO: Test history lines don't change with this (!51 to execute 51 command)
  # TODO: See https://unix.stackexchange.com/questions/1288/
  # TODO: BUG: when ${PWD} contains a newline (colors entire line)
  history -a  # Append command immediately to history
  #history -c  # Clear current history for session
  #history -r  # Read history back into memory (get history from active bash's)
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
