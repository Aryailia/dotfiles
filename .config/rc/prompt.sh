#!/bin/sh
  # for setting the indent
# Depends on sudo and git

NL='
'
   exitcode="${1:-"N/A"}" # I should be passed "$?"
      timer="${2:-0}"
 background="${3:-0}"     # I should be passed "$!"
 escapeopen="$4"
escapeclose="$5"
#backgroundpid="${3:-0}"

# https://stackoverflow.com/questions/24839271 for using \001 and \002 for bash
# They stop bash from restricting the width (typing after PS1 runs to see)
  black="${escapeopen}\\033[40m${escapeclose}"
    red="${escapeopen}\\033[41m${escapeclose}"
  green="${escapeopen}\\033[42m${escapeclose}"
 yellow="${escapeopen}\\033[43m${escapeclose}"
   blue="${escapeopen}\\033[44m${escapeclose}"
magenta="${escapeopen}\\033[45m${escapeclose}"
   cyan="${escapeopen}\\033[46m${escapeclose}"
  white="${escapeopen}\\033[47m${escapeclose}"

  whitetext="${escapeopen}\\033[0;37m${escapeclose}"
  blacktext="${escapeopen}\\033[0;30m${escapeclose}"
      RESET="${escapeopen}\\033[0;0m${escapeclose}"
# If I ever wanted to toy with powerline character again
#local powerline=$'\uE0B0'
#local green2yellow=$'\[\033[32;43m\]'
#local yellow2black=$'\[\033[33;40m\]'

# Box drawing characters
bout() { printf %b "$@"; }
bout "${RESET}┬${whitetext}${black}"

###
# Depth of process call tree, useful for knowing if we are in subshells
bout "${magenta} "
ps hf | awk -v pid="$$" '
  $3 ~ /s/  { stack = 1; }  # Start {stack} at session leader
  1         { stack += 1; }
  $1 == pid { printf "%s ", stack; exit 0; }
'

###
# Vary the colour of username depending on whether sudo is alive or not
#
# Check if sudo still alive by sudo with error (nothing) as password
# Returns empty if alive || lacks permissions / requires password
if [ -z "$( sudo --non-interactive --validate 2>&1 )" ]
  then bout "${magenta} ${USER} "
  else bout "${green} ${USER} "
fi

###
# Attach hostname to username with no space and trunk hostname to six
#bout "${yellow}\$(echo '\\h' | cut -c1-6) "
#bout "${yellow2black}${powerline}${whitetext}"
bout "${yellow}$( cat /etc/hostname ) "


# will test before doing anything with this
# https://unix.stackexchange.com/questions/9605/how-can-i-detect-if-the-shell-is-controlled-from-ssh

###
# Add exit code of last command
bout "${black} ${exitcode} "

###
#
bout "${blue} "
[ "${PWD}" != "${PWD#"${HOME}"}" ] && bout "~"
bout "${PWD#"${HOME}"} "


###
# Attach branch name and file revision count if in a git active directory
# Source: Parth - https://github.com/Parth/dotfiles
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  bout "${cyan} $( git rev-parse --abbrev-ref HEAD 2>/dev/null ) "
  change_count="$( git status --short | wc -l )"
  [ "${change_count}" -gt 0 ] && bout "${red}+${change_count} "
fi

###
# Time+idle seconds since last commands if long, terminal-emulator-specific
#
# Look at trap 'timer' DEBUG if I want to skip delay timer, too hacky for me
# If too much idle time, can just enter to set to 0 again
if [ "${timer}" -gt 180 ]; then
  bout "${magenta} "
  if   [ "${timer}" -lt 250 ]; then
    bout "${timer}s"
  elif [ "${timer}" -lt 3600 ]; then
    bout "$((timer / 60))m$((timer % 60))s"
  elif [ "${timer}" -lt 86400 ]; then
    bout "$((timer / 3600))s$(( timer % 3600 / 60 ))m"
  else
    bout "$((timer / 86400))d$(( timer % 86400 / 3600 ))h"
  fi
  bout " "
fi

###
# PID - Sometimes backgrounding does not check process
# https://stackoverflow.com/questions/1570262
# `kill -0 ` errors if process not running or unable to send signals to process
[ "${background}" != "" ] && [ "${background}" !=  "0" ] \
    && kill -0 "${background}" >/dev/null 2>&1 \
  && bout "${white}${blacktext} PID&:${background} "

bout "${RESET}${NL}└─"
bout "${RESET}"
printf ' '  # Six-per-em space U+2006, marker to easily search history
# Use `Ctrl + V;  u2006` to enter this in vim
