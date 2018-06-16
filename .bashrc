# Enable XON/XOFF, usually C-q and C-s respectively
stty -ixon
#PS1='[\u@\h \W]\$ '
PROMPT_COMMAND="b"

b() {
  #local red="\[\033[0;41;30m\]"
  #local green="\[\033[0;32m\]"
  #local brown="\[\033[0;33m\]"
  #local blue="\[\033[0;34m\]"
  #local purple="\[\033[0;35m\]"
  #local cyan="\[\033[0;46;30m\]"
  #local clear="\[\033[0m\]"

  local start="\[\033[1;37m\]"
  local red="\[\033[41m\]"
  local green="\[\033[42m\]"
  local brown="\[\033[43m\]"
  local blue="\[\033[44m\]"
  local purple="\[\033[45m\]"
  local cyan="\[\033[46m\]"
  local clear="\[\033[0m\]"

  #local red="\[\033[0;41m\]"
  #local green="\[\033[0;42;1;37m\]"
  #local brown="\[\033[7;43;1;37m\]"
  #local blue="\[\033[0;44;1;37m\]"
  #local purple="\[\033[0;45;1;37m\]"
  #local cyan="\[\033[0;46m\]"
  #local clear="\[\033[0m\]"
  PS1="$start"
  
  #local SUDO_TIMER=$(sudo -n uptime 2>&1 | grep 'load')
  if [ "$(sudo -n uptime 2>&1 | grep 'load')" ]
    then PS1+="$purple \\u "
    else PS1+="$green \\u "
  fi

  PS1+="$invert$brown\\h "

  # lookup how $(debian_chroot:+$(debian_chroot)) works

  # add ssh checks to env_keep in sudoers to make it available across su?
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
  
  #using_su=whoami | grep -vq "$(logname)"
  #$using_su && echo 'am i'

  # Only current directory since ls shows rest
  PS1+="$blue \\W "

  # git
  if git rev-parse --is-inside-work-tree 2>/dev/null | grep --quiet 'true'; then
    PS1+="$cyan "
    PS1+="$(git rev-parse --abbrev-ref HEAD 2> /dev/null) "
    local change_count=$(git status --short | wc -l)
    # intentionally not adding space
    [ $change_count -gt 0 ] && PS1+="$red+$change_count "
  fi

  # Probaby non-POSIX, but shows seconds past since last line for long commands
  # includes idle time between commands, but I do not want to hack around this
  # If too much idle time, can just C-l, enter, etc. to set to 0 again
  if [ $SECONDS -gt 120 ]; then
    PS1+="$purple ${SECONDS}s "
  fi
  SECONDS=0

  # PID of any background script
  #[ -n "$!" ] && [ "$!" !=  0 ] && PS1+="$purple PID:$! "
  
  PS1+="$clear "

}

c() {
  # quote for literal cd, subshell because ls is an allias 
  "cd" "$1" && (ls -a)
}


alias ls='pwd;ls --color=auto '
alias cd='c '
alias rf='source ~/.bashrc'
