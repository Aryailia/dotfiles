#!/usr/bin/env bash
  # Included shebang for shellcheck. Indent for autodetect indent
# This originally runs for non-login (terminals after X launched)
# If sourced manually from '.profile', runs for all terminal instances

#shopt -s autocd  # cd without typing cd just typing name. Conflicts too much

#export GPG_TTY="$( tty )"

# History modification, https://sanctum.geek.nz/arabesque/better-bash-history
#HISTFILESIZE=10000             # Commands to save to disk (default 500)
#HISTSIZE="${HISTFILESIZE}"     # Portion of which to load into memory
#HISTTIMEFORMAT='%F %T '        # Format to record time executed
#HISTCONTROL='ignoreboth'       # 'ignoreboth' is the following:
                               # - 'ignorespace': commands preceded by spaces
                               # - 'ignoredups':  squash uninterrupted repeats
#HISTIGNORE='ls:bg:fg:history'  # Do not log these commands
shopt -s histappend            # History is added
#shopt -s cmdhist               # Join multi-line commands onto a single line

exists() {
  for temp in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${temp}/$1" ] && [ -x "${temp}/$1" ] && {
      printf %s "${temp}/$1"
      return 0
    }
  done
  return 1
}

# Bash specific stuff
rrc() {
  if [ "$#" = 0 ]; then
    source "${HOME}/.bashrc"
    source "${HOME}/.profile"
  fi
  source "${XDG_CONFIG_HOME}/envrc"
  source "${XDG_CONFIG_HOME}/aliasrc"
}

# Android Termux: Bash never ran as login shell, thus '.profile' never sourced
[ -z "${XDG_CONFIG_HOME}" ] && source "${HOME}/.profile"
# Nee
rrc 'Avoid infinite loop'

# Use `cat` instead of a function so we do not pollute namespace
# https://stackoverflow.com/questions/24839271 for using \001 and \002
# They stop bash from restricting the width (typing after PS1 runs to see)
PROMPT_COMMAND="$(<<EOF cat -
  errorcode="\$?"
  # More history syncing hackery (bash saves history once session closes)
  # TODO: Test history lines don't change with this (!51 to execute 51 command)
  # TODO: See https://unix.stackexchange.com/questions/1288/
  # TODO: BUG: when ${PWD} contains a newline (colors entire line)
  history -a  # Append command immediately to history
  #history -c  # Clear current history for session
  #history -r  # Read history back into memory (get history from active bash's)
  PS1="\$( "${XDG_CONFIG_HOME}/prompt.sh" \
    "\$errorcode" "\$SECONDS" "\$!" "\\001" "\\002"
  )"
  SECONDS="0"
EOF
)"

cd_of() {
  temp="$( "$@"; err="$?"; printf x; exit "${err}" )" || return "$?"
  temp="${temp%x}"
  if [ "${temp}" != "${PWD}" ]; then
    cd "${temp}" && ls --color=auto --group-directories-first -hA
  fi
}

if test -z "${XDG_RUNTIME_DIR}"; then
  export XDG_RUNTIME_DIR="/tmp/${UID}-runtime-dir"
  if ! test -d "${XDG_RUNTIME_DIR}"; then
    mkdir "${XDG_RUNTIME_DIR}"
    chmod 0700 "${XDG_RUNTIME_DIR}"
  fi
fi
