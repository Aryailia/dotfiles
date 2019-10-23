

function exists {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && {
      printf %s "${dir}/$1"
      return 0
    }
  done
  return 1
}

function rrc {
  [ "$#" = "0" ] && source "${ZDOTDIR}/.zshrc" "${HOME}/.profile"
  source "${XDG_CONFIG_HOME}/envrc"
  source "${XDG_CONFIG_HOME}/aliasrc"
}
rrc "Avoid infinite loop"

# Not exactly sure how this works
# but `compinit` allows arrow navigation of menu
autoload -Uz compinit
zstyle ':completion:*' menu select                     # Show tab-navigable menu
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}  # Color with ls
unsetopt listambiguous  # Single tab for menu
_comp_options+=(globdots)  # Include hidden files in autcomplete
zmodload zsh/complist
compinit

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# https://unix.stackexchange.com/questions/273861/unlimited-history-in-zsh
# man zshoptions
export HISTSIZE=10000            # Set history size
export SAVEHIST=10000            # save history after logout
export HISTFILE="${XDG_CACHE_HOME}/.zhistory"
setopt EXTENDED_HISTORY          # record in ":start:elapsed;command" format
setopt HIST_IGNORE_DUPS          # Do not record repeated commands
setopt HIST_IGNORE_SPACE         # Do not record commands starting with a space
setopt HIST_REDUCE_BLANKS        # Remove superfluous whitespace from history

export KEYTIMEOUT=1
#bindkey -v

# Change cursor shape for different vi modes.
#function zle-keymap-select {
#  if [[ ${KEYMAP} == vicmd ]] ||
#     [[ $1 = 'block' ]]; then
#    echo -ne '\e[1 q'
#
#  elif [[ ${KEYMAP} == main ]] ||
#       [[ ${KEYMAP} == viins ]] ||
#       [[ ${KEYMAP} = '' ]] ||
#       [[ $1 = 'beam' ]]; then
#    echo -ne '\e[5 q'
#  fi
#}
#zle -N zle-keymap-select
#
#zle-line-init() {
#    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
#    echo -ne "\e[5 q"
#}
#zle -N zle-line-init

function precmd() {
  local errorcode="$?"
  local SECONDS=0
  local prompter="${XDG_CONFIG_HOME}/prompt.sh"
  PS1="$( "${prompter}" "${errorcode}" "${SECONDS}" "$!" '%{' '%}' )"
  #PS1="%{$( "${prompter}" "${errorcode}" "${SECONDS}" "$!" )%}"
}


function cd_of {
  local temp="$("$@"; err="$?"; printf x; exit "${err}")" || return "$?"
  temp="${temp%x}"
  if [ "${temp}" != "${PWD}" ]; then
    cd "${temp}" && ls --color=auto --group-directories-first -hA
  fi
}
