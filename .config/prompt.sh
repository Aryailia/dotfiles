#!/usr/bin/env sh
  # for setting the indent
# Depends on sudo and git
# https://stackoverflow.com/quesionts/24839271 for using \001 and \002
# https://stackoverflow.com/quesionts/301353 for explanation

exitcode="${1:-"N/A"}" # I should be passed "$?"
   timer="${2:-0}"
#backgroundpid="${3:-0}"

  black='\001\033[40m\002'
    red='\001\033[41m\002'
  green='\001\033[42m\002'
  brown='\001\033[43m\002'
   blue='\001\033[44m\002'
magenta='\001\033[45m\002'
   cyan='\001\033[46m\002'
  white='\001\033[47m\002'

  whitetext='\001\033[1;37m\002'
  blacktext='\001\033[1;30m\002'
formatclear='\001\033[0m\002'
# If I ever wanted to toy with powerline character again
#local powerline=$'\uE0B0'
#local green2brown=$'\[\033[32;43m\]'
#local brown2black=$'\[\033[33;40m\]'

text="$whitetext"
p() { printf '%s' "$@"; }
add() { text="$text$*"; }


###
# Vary the colour of username depending on whether sudo is alive or not
#
# Check if sudo still alive by sudo with error (nothing) as password
# Returns empty if alive || lacks permissions / requires password
if [ -z "$(sudo --non-interactive --validate 2>&1)" ]
  then add "$magenta $USER "
  else add "$green $USER "
fi

###
# Attach hostname to username with no space and trunk hostname to six
#add "$brown\$(echo '\\h' | cut -c1-6) $brown2black$powerline$whitetext"
add "$brown$(hostname | cut -c1-6) "


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
add "$black $exitcode "


###
# Only current directory since ls shows rest
# Always has / prepended
# Want to use '/' as the sed deliminter because folders cannot have '/' in name
if   [ "$PWD" = "$HOME" ]; then workingdir='~'
elif [ "$PWD" = "/" ];     then workingdir='/'
else                            workingdir="/$(basename "$PWD")"; fi
add "$blue $workingdir "


###
# Attach branch name and file revision count if in a git active directory
# Source: Parth - https://github.com/Parth/dotfiles
if git rev-parse --is-inside-work-tree 2>/dev/null | grep --quiet 'true'; then
  add "$cyan $(git rev-parse --abbrev-ref HEAD 2>/dev/null) "
  change_count=$(git status --short | wc -l)
  [ "$change_count" -gt 0 ] && add "$red+$change_count "
fi

###
# Time+idle seconds since last commands if long, terminal-emulator-specific
#
# Look at trap 'timer' DEBUG if I want to skip delay timer, too hacky for me
# If too much idle time, can just enter to set to 0 again
[ $timer -gt 180 ] && add "$magenta ${timer}s "

###
# PID of backgrounded scripts, commands usually report this so kinda useless?
# Source: Parth - https://github.com/Parth/dotfiles
[ -n "$!" ] && [ "$!" !=  0 ] && add "$yellow PID:$! "
  
printf '%b%b' "$text" "$formatclear "
#printf '%b%b%b' "$text" "$formatclear" "\002"
#printf '%b' "\001\033[32m\002cheese\001\033[0m\002"
#echo -e "\[$text$formartclear\033[0m \]"

