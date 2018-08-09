#!/usr/bin/env bash
  #:!console bash %self

#file="~/.bashrc";                   test -f "$file" && source "$file"
file="$HOME/.config/shell_profile"; test -f "$file" && source "$file"
file="$HOME/.config/shellrc";       test -f "$file" && source "$file"

PROMPT_COMMAND='b'
alias rrc='source ~/.bash_profile'
c() { cd "$(namedpath "$1")"; lx .; }
b() { PS1="$(~/.config/prompt.sh "$?" "$SECONDS")"; SECONDS="0"; }


# https://gist.github.com/rtfpessoa/811701ed8fa642f60e411aef04b2b64a 
#
# NVM lazy loading script

NVM_DIR="$HOME/.nvm"

# Skip adding binaries if there is no node version installed yet
if [ -d $NVM_DIR/versions/node ]; then
  NODE_GLOBALS=(`find $NVM_DIR/versions/node -maxdepth 3 \( -type l -o -type f \) -wholename '*/bin/*' | xargs -n1 basename | sort | uniq`)
fi
NODE_GLOBALS+=("nvm")


load_nvm () {
  # Unset placeholder functions
  for cmd in "${NODE_GLOBALS[@]}"; do unset -f ${cmd} &>/dev/null; done

  # Load NVM
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

  # (Optional) Set the version of node to use from ~/.nvmrc if available
  nvm use 2> /dev/null 1>&2 || true

  # Do not reload nvm again
  export NVM_LOADED=1
}

for cmd in "${NODE_GLOBALS[@]}"; do
  # Skip defining the function if the binary is already in the PATH
  if ! which ${cmd} &>/dev/null; then
    eval "${cmd}() { unset -f ${cmd} &>/dev/null; [ -z \${NVM_LOADED+x} ] && load_nvm; ${cmd} \$@; }"
  fi
done
