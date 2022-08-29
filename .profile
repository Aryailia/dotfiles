#!/usr/bin/env sh
# This runs for 'login' bash terminals (so virtual console)
# This is sourced by all the random terminal emulators I am using

# `fish` does not support `${VAR}` variable reference
# `fish` does not support `$( printf )` subshells (supports `( printf )`)
# `ion` does not support `[ -z A ]` test syntax
# `ion` does not support `A=B` variable declaration (but supports `export A=B`)
# `ion` does not support 2> or &1

# The defaults, but set them explicitly
export XDG_CACHE_HOME="$HOME/.cache"        # analogous to /etc
export XDG_CONFIG_HOME="$HOME/.config"      # analogous to /var/cache
export XDG_DATA_HOME="$HOME/.local/share"   # analogous to /usr/share
export XDG_STATE_HOME="$HOME/.local/state"  # analogous to /var/lib
#XDG_RUNTIME_DIR set in .xprofile

export SVDIR="$XDG_CONFIG_HOME/autostart/sv-user"

command -v 'lynx'            >/dev/null 2>&1 && export  BROWSER_CLI='lynx'
command -v 'st'              >/dev/null 2>&1 && export     TERMINAL='st'
command -v 'kitty'           >/dev/null 2>&1 && export     TERMINAL='kitty'
command -v 'alacritty'       >/dev/null 2>&1 && export     TERMINAL='alacritty'
command -v 'xst'             >/dev/null 2>&1 && export     TERMINAL='xst'
command -v 'vim'             >/dev/null 2>&1 && export       EDITOR='vim'
command -v 'nvim'            >/dev/null 2>&1 && export       EDITOR='nvim'
command -v 'termux-open-url' >/dev/null 2>&1 && export      BROWSER='termux-open-url'
command -v 'surf'            >/dev/null 2>&1 && export      BROWSER='surf'
command -v 'firefox'         >/dev/null 2>&1 && export      BROWSER='firefox'
command -v 'zathura'         >/dev/null 2>&1 && export       READER='zathura'
#command -v 'st'              >/dev/null 2>&1 && export OPT_TERMNAME='-t'
#command -v 'alacritty'       >/dev/null 2>&1 && export OPT_TERMNAME='-t'


################################################################################
# $HOME directory cleanup, https://superuser.com/questions/874901/

# Programming
export npm_config_userconfig="$XDG_CONFIG_HOME/rc/npmrc"
export npm_config_cache="$XDG_DATA_HOME/npm"
export npm_config_prefix="$HOME/.local" # No XDG var for ~/.local
export NODE_REPL_HISTORY=''
export NODE_PATH="$npm_config_prefix/lib/node_modules"
export CARGO_HOME="$HOME/.local/lib/cargo"   # For source files
export CARGO_INSTALL_ROOT="$HOME/.local"     # For binaries
export RUSTUP_HOME="$HOME/.local/lib/rustup" # Rustup source files
export GOPATH="$HOME/.local/lib/go"
export GOBIN="$HOME/.local/bin"              # For binaries
export R_HISTFILE="/dev/null"
export GEM_HOME="$HOME/.local/lib/gem"
export GEM_PATH="$GEM_HOME"
export GEM_SPEC_CACHE="$XDG_CACHE_HOME/lib/gem"

# Important
export GNUPGHOME="$HOME/.local/gnupg"
export PASSWORD_STORE_DIR="$HOME/.local/password-store"

# Non-programming
export EMACSINIT="$XDG_CONFIG_HOME/emacs"
export VIMINIT='let $MYVIMRC="$XDG_CONFIG_HOME/vim/init.vim" | source $MYVIMRC'
export LYNX_CFG="$XDG_CONFIG_HOME/lynx/lynx.cfg"
export LYNX_LSS="$XDG_CONFIG_HOME/lynx/lynx.lss"
export WGETRC="$XDG_CONFIG_HOME/rc/wgetrc"
export PYTHONSTARTUP="$XDG_CONFIG_HOME/rc/pythonrc"
export NOTMUCH_CONFIG="$XDG_CONFIG_HOME/rc/notmuch-config"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtkrc-2.0"
export LESSHISTFILE='/dev/null'
export INPUTRC="$XDG_CONFIG_HOME/rc/inputrc"
export ZDOTDIR="$HOME/.config/zsh"

################################################################################
export STARDICT_DATA_DIR="$XDG_DATA_HOME/stardict" # looks in ./dic
export SDCV_HISTSIZE="0"

# History modification, https://sanctum.geek.nz/arabesque/better-bash-history
export HISTFILE="$XDG_CACHE_HOME/history"
export HISTFILESIZE=10000        # Commands to save to disk (default 500)
export HISTSIZE="$HISTFILESIZE"  # Portion of which to load into memory
export HISTTIMEFORMAT='%F %T '   # Format to record time executed
export HISTCONTROL='ignoreboth'  # 'ignoreboth' is the following:
                                 # - 'ignorespace': commands preceded by spaces
                                 # - 'ignoredups':  squash uninterrupted repeats
export HISTIGNORE='ls:bg:fg:history'  # Do not log these commands

# PATH
export SCRIPTS="$XDG_CONFIG_HOME/scripts"
printf %s\\n ":$PATH:" | grep -q ":$SCRIPTS:" \
  || export PATH="$PATH:$SCRIPTS"
printf %s\\n ":$PATH:" | grep -q ":$HOME/.local/bin:" \
  || export PATH="$PATH:$HOME/.local/bin"
printf %s\\n ":$PATH:" | grep -q ":$CARGO_HOME/bin:" \
  || export PATH="$PATH:$CARGO_HOME/bin"
test -d /opt/texlive/2021/bin/x86_64-linux/ \
  && export PATH="$PATH:/opt/texlive/2021/bin/x86_64-linux/"


# Directories
export DOTENVIRONMENT="$HOME/.environment"
export ZETTELKASTEN_DIR="$DOTENVIRONMENT/zettelkasten"
export BIBLIOGRAPHY="$DOTENVIRONMENT/Library/bibliography.bib"
uname -o | grep -q 'Linux' && export TMPDIR='/tmp'  # Linux/MacOS
uname -o | grep -q 'MSYS' &&  export TMPDIR="$HOME/AppData/Local/Temp"  # Win

# Default programs
## $DISPLAY is to check if X server is running
#test -n "$DISPLAY" && command -v st >/dev/null 2>&1 && export TERMINAL='st'
## Working non sh version for both ion and bash
#printf %s "$PATH" | xargs -n1 -d: -IZ test --e '/.Z/st' && export TEMRINAL=st

# Less/manpages colors, 'fish' uses `sed` to read these
export PAGER='less'  # for perldoc
export LESS=-R
export LESS_TERMCAP_mb="$( printf '%b' '[1;31m' )"
export LESS_TERMCAP_md="$( printf '%b' '[1;36m' )"
export LESS_TERMCAP_me="$( printf '%b' '[0m' )"
export LESS_TERMCAP_so="$( printf '%b' '[01;44;33m' )"
export LESS_TERMCAP_se="$( printf '%b' '[0m' )"
export LESS_TERMCAP_us="$( printf '%b' '[1;32m' )"
export LESS_TERMCAP_ue="$( printf '%b' '[0m' )"

# Having 'envrc' sourced is mildly important for regular function
# Source .bashrc to have the same environment in tty as in Xorg
# Login shell starts with '-bash', test if it ends with bash
printf %s\\n "$0" | grep -q '^-bash$' \
  && test -f "$HOME/.bashrc" && . "$HOME/.bashrc" \
#  && which loadkeys >/dev/null \
#  && sudo loadkeys "$XDG_CONFIG_HOME/rc/remap-caps-rctrl.map"

