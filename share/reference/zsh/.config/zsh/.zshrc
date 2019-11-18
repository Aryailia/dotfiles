export GPG_TTY="$( tty )"

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

# Prefer Vim shortcuts
#bindkey -v
#DEFAULT_VI_MODE=viins
#export KEYTIMEOUT=1
#
## Change cursor shape for different vi modes.
#zle-keymap-select() {
#  if [[ ${KEYMAP} == vicmd ]] ||
#     [[ $1 = 'block' ]]; then
#    #echo -ne '\e[1 q'
#    print -n -- "\e[1 q"
#
#  elif [[ ${KEYMAP} == main ]] ||
#       [[ ${KEYMAP} == viins ]] ||
#       [[ ${KEYMAP} = '' ]] ||
#       [[ $1 = 'beam' ]]; then
#    print -n -- "\e[5 q"
#    #echo -ne '\e[5 q'
#    #notify.sh 'hello'
#  fi
#}
#
#zle-line-init() {
#    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
#    echo -ne "\e[5 q"
#}
#
#zle -N zle-line-init
#zle -N zle-keymap-select



# Prefer vi shortcuts
bindkey -v
DEFAULT_VI_MODE=viins
KEYTIMEOUT=1

__set_cursor() {
    local style
    case $1 in
        reset) style=0;; # The terminal emulator's default
        blink-block) style=1;;
        block) style=2;;
        blink-underline) style=3;;
        underline) style=4;;
        blink-vertical-line) style=5;;
        vertical-line) style=6;;
    esac

    [ $style -ge 0 ] && print -n -- "\e[${style} q"
}

# Set your desired cursors here...
__set_vi_mode_cursor() {
    case $KEYMAP in
        vicmd)
          __set_cursor block
          ;;
        main|viins)
          __set_cursor vertical-line
          ;;
    esac
}

__get_vi_mode() {
    local mode
    case $KEYMAP in
        vicmd)
          mode=NORMAL
          ;;
        main|viins)
          mode=INSERT
          ;;
    esac
    print -n -- $mode
}

zle-keymap-select() {
    __set_vi_mode_cursor
    zle reset-prompt
}

zle-line-init() {
    zle -K $DEFAULT_VI_MODE
}

zle -N zle-line-init
zle -N zle-keymap-select

# Optional: allows you to open the in-progress command inside of $EDITOR
autoload -Uz edit-command-line
bindkey -M vicmd 'v' edit-command-line
zle -N edit-command-line

# PROMPT_SUBST enables functions and variables to re-run everytime the prompt
# is rendered
setopt PROMPT_SUBST

# Single quotes are important so that function is not run immediately and saved
# in the variable
RPROMPT='$(__get_vi_mode)'



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
