#!/usr/bin/env bash
  #:!console bash %self
# For interactive shells (login and non-login) and all subprocesses
# Since this affects the first login shell too, this is sourced by most things

shopt -q login_shell && {
  export TERM=linux
  [ -f ~/.bashrc ] && source ~/.bashrc
  [ -f ~/.config/shell_profile ] && source ~/.config/shell_profile
}
