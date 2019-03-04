#!/usr/bin/env bash
  #:!console bash %self
# Profile runs on login shells

file="$HOME/.bashrc";               [ -f "$file" ] && source "$file"
file="$HOME/.config/shell_profile"; [ -f "$file" ] && source "$file"

