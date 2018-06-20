#!/bin/sh
# Enable XON/XOFF, usually C-q and C-s respectively
stty -ixon
#PS1='[\u@\h \W]\$ '
PROMPT_COMMAND="b"

alias ls='pwd;ls --color=auto '
alias cd='c '
alias rb='source ~/.bashrc' # r[eload] b[ashrc]
alias rx='xrdb ~/.Xresources' # r[eload] X[resources]
npm-exec() { $(printf "%s/%s" "$(npm bin)" "$*"); } # run locally install package

# I like single letter commands since they interefere less with tab completion
# c[d]
c() { 'cd' "$1" && (ls -a); }  # quote cd and subshell ls cause alliases

# b[ash] - prompt command
b() {
  local code="$?" # this must be first
  local whitetext='\[\033[1;37m\]'
  local black='\[\033[40m\]'
  local red='\[\033[41m\]'
  local green='\[\033[42m\]'
  local brown='\[\033[43m\]'
  local blue='\[\033[44m\]'
  local magenta='\[\033[45m\]'
  local cyan='\[\033[46m\]'
  local clear='\[\033[0m\]'

  PS1="$whitetext"
  
  ###
  # Vary the colour of username depending on whether sudo is alive or not
  #
  # Check if sudo still alive by sudo with error (nothing) as password
  # Returns empty if alive || lacks permissions / requires password
  if [ -z "$(sudo -n -v 2>&1)" ]
    then PS1="$PS1$magenta \\u "
    else PS1="$PS1$green \\u "
  fi

  ###
  # Attach hostname to username with no space and trunk hostname to six
  PS1="$PS1$brown\$(echo '\\h' | cut -c1-6) "

  ###
  # @todo
  #
  # - lookup how $(debian_chroot:+$(debian_chroot)) works
  #
  # - add ssh checks to env_keep in sudoers to make it available across su?
  # also $SSH_CONNECTION
  # will test before doing anything with this
  # https://unix.stackexchange.com/questions/9605/how-can-i-detect-if-the-shell-is-controlled-from-ssh
  #if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  #  SESSION_TYPE=remote/ssh
  #  # many other tests omitted
  #else
  #  case $(ps -o comm= -p $PPID) in
  #    sshd|*/sshd) SESSION_TYPE=remote/ssh;;
  #  esac
  #fi
  #
  ### 
  #using_su=whoami | grep -vq "$(logname)"
  #$using_su && echo 'am i'

  ###
  # Add exit code of last command
  PS1="$PS1$black $code "

  ###
  # Only current directory since ls shows rest
  PS1="$PS1$blue \\W "

  ###
  # Attach branch name and file revision count if in a git active directory
  # Source: Parth - https://github.com/Parth/dotfiles
  if git rev-parse --is-inside-work-tree 2>/dev/null | grep --quiet 'true'; then
    PS1="$PS1$cyan "
    PS1="$PS1$(git rev-parse --abbrev-ref HEAD 2> /dev/null) "
    local change_count
    change_count=$(git status --short | wc -l)
    # intentionally not adding space
    [ "$change_count" -gt 0 ] && PS1="$PS1$red+$change_count "
  fi

  ###
  # Time+idle seconds since last commands if long, terminal-emulator-specific
  #
  # Look at trap 'timer' DEBUG if I want to skip delay timer, too hacky for me
  # If too much idle time, can just enter to set to 0 again
  if [ $SECONDS -gt 120 ]; then
    PS1="$PS1$magenta ${SECONDS}s "
  fi
  SECONDS=0

  ###
  # PID of backgrounded scripts, commands usually report this so kinda useless?
  # Source: Parth - https://github.com/Parth/dotfiles
  #[ -n "$!" ] && [ "$!" !=  0 ] && PS1+="$yellow PID:$! "
  
  PS1="$PS1$clear "

}

