#!/usr/bin/env sh

export DULL=0
export BRIGHT=1  # Can also mean bold

export NULL=00   # ForeGround and BackGround

export FG_BLACK=30
export FG_RED=31
export FG_GREEN=32
export FG_YELLOW=33
export FG_BLUE=34
export FG_VIOLET=35
export FG_CYAN=36
export FG_WHITE=37

export BG_BLACK=40
export BG_RED=41
export BG_GREEN=42
export BG_YELLOW=43
export BG_BLUE=44
export BG_VIOLET=45
export BG_CYAN=46
export BG_WHITE=47

export A="\001\033["  # Opening
export B="m\002"      # Closing
export NORMAL="$A$B"  # Not really sure what this is for
export RESET="$A${DULL};${NULL}$B"  # Reset to default

export BLACK="$A${DULL};${FG_BLACK}$B"
export RED="$A${DULL};${FG_RED}$B"
export GREEN="$A${DULL};${FG_GREEN}$B"
export YELLOW="$A${DULL};${FG_YELLOW}$B"
export BLUE="$A${DULL};${FG_BLUE}$B"
export VIOLET="$A${DULL};${FG_VIOLET}$B"
export CYAN="$A${DULL};${FG_CYAN}$B"
export WHITE="$A${DULL};${FG_WHITE}$B"

#export BRIGHT_BLACK="$A${BRIGHT};${FG_BLACK}$B"
