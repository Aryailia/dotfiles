# Path
# Using `test` instead of `[ -z A ]` syntax to support more shells
# `ion` does not support `[ -z A ]` test syntax
# `ion` does not support `A=B` variable declaration (but `export A=B` works)
# `ion` does not support 2>&1

# PATH
export SCRIPTS="${HOME}/.config/scripts"
export GOPATH="${HOME}/.local/go"
printf %s\\n "${PATH}" | grep -q ":${SCRIPTS}:" \
  || export PATH="${PATH}:${SCRIPTS}"
printf %s\\n "${PATH}" | grep -q ":${HOME}/.cargo/bin:" \
  || export PATH="${PATH}:${HOME}/.cargo/bin"

# Folders
export DOTENVIRONMENT="${HOME}/.environment"
uname -o | grep -q 'Linux' && export TMPDIR='/tmp'  # Linux/MacOS
uname -o | grep -q 'MSYS' &&  export TMPDIR="${HOME}/AppData/Local/Temp"  # Win

# ${HOME} directory cleanup
export NOTMUCH_CONFIG="${HOME}/.config/notmuch-config"
export GTK2_RC_FILES="${HOME}/.config/gtk-2.0/gtkrc-2.0"
export LESSHISTFILE="/dev/null"
export INPUTRC="${HOME}/.config/inputrc"

## Default programs
### ${DISPLAY} is to check if X server is running
##test -n "${DISPLAY}" && command -v st >/dev/null 2>&1 && export TERMINAL='st'
sh -c 'which st  >/dev/null 2>&1'             && export TERMINAL='st'
sh -c 'which vim >/dev/null 2>&1'             && export EDITOR='vim'
sh -c 'which vim >/dev/null 2>&1'             && export EDITOR='vim'
sh -c 'which nvim >/dev/null 2>&1'            && export EDITOR='nvim'
sh -c 'which termux-open-url >/dev/null 2>&1' \
  && export BROWSER='termux-open-url'
sh -c 'which midori >/dev/null 2>&1'          && export BROWSER='midori'
sh -c 'which surf >/dev/null 2>&1'            && export BROWSER='surf'
sh -c 'which zathura >/dev/null 2>&1'         && export READER='zathura'

# Less/manpages colors
export LESS=-R
export LESS_TERMCAP_mb="$(printf '%b' '[1;31m')"
export LESS_TERMCAP_md="$(printf '%b' '[1;36m')"
export LESS_TERMCAP_me="$(printf '%b' '[0m')"
export LESS_TERMCAP_so="$(printf '%b' '[01;44;33m')"
export LESS_TERMCAP_se="$(printf '%b' '[0m')"
export LESS_TERMCAP_us="$(printf '%b' '[1;32m')"
export LESS_TERMCAP_ue="$(printf '%b' '[0m')"

# Source .bashrc to have the same environment in tty as in Xorg
# Login shell starts with '-bash', test if it ends with bash
printf %s\\n "$0" | grep -q 'bash$' \
  && test -f "${HOME}/.bashrc" \
  && . "${HOME}/.bashrc"
