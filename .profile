# Path
# Using `test` instead of `[ ]` syntax to support more shells

SCRIPTS="${HOME}/.config/scripts"
#PATH="${PATH}:${SCRIPTS}"
PATH="${PATH}$(find "${SCRIPTS}"/ -type d -exec printf :%s '{}' \;)"
PATH="${PATH}:${HOME}/.cargo/bin"
GOPATH="${HOME}/.local/go"
export PATH GOPATH

# Folders
DOTENVIRONMENT="${HOME}/.environment"
uname -o | grep -q 'Linux' && TMPDIR='/tmp'  # Linux/MacOS
uname -o | grep -q 'MSYS' &&  TMPDIR="${HOME}/AppData/Local/Temp"  # Win
export SCRIPTS TMPDIR

# ${HOME} directory cleanup
export NOTMUCH_CONFIG="${HOME}/.config/notmuch-config"
export GTK2_RC_FILES="${HOME}/.config/gtk-2.0/gtkrc-2.0"
export LESSHISTFILE="/dev/null"
export INPUTRC="${HOME}/.config/inputrc"

# Default programs
## ${DISPLAY} is to check if X server is running
#test -n "${DISPLAY}" && command -v st >/dev/null 2>&1 && export TERMINAL='st'
command -v st >/dev/null 2>&1               && TERMINAL='st'
command -v vim >/dev/null 2>&1              && EDITOR='vim'
command -v nvim >/dev/null 2>&1             && EDITOR='nvim'
command -v termux-open-url >/dev/null 2>&1  && BROWSER='termux-open-url'
command -v midori >/dev/null 2>&1           && BROWSER='midori'
command -v surf >/dev/null 2>&1             && BROWSER='surf'
command -v zathura >/dev/null 2>&1          && READER='zathura'
export TERMINAL EDITOR BROWSER READER

# Less/manpages colors
export LESS=-R
export LESS_TERMCAP_mb="$(printf '%b' '[1;31m')"
export LESS_TERMCAP_md="$(printf '%b' '[1;36m')"
export LESS_TERMCAP_me="$(printf '%b' '[0m')"
export LESS_TERMCAP_so="$(printf '%b' '[01;44;33m')"
export LESS_TERMCAP_se="$(printf '%b' '[0m')"
export LESS_TERMCAP_us="$(printf '%b' '[1;32m')"
export LESS_TERMCAP_ue="$(printf '%b' '[0m')"

test "${0%bash}" != "$0" && test -f "${HOME}/.bashrc" && . "${HOME}/.bashrc"
