#!/usr/bin/env sh
# Commands to run when xserver is started

# Place majority of commands in '.xprofile' because '.xprofile' commands are
# run when someone logins via the display manager (login screen)
[ -f  "${HOME}/.xprofile" ] && . "${HOME}/.xprofile"

# set display size
# xrandr -s 800x600

#setterm -blength 0 # remove beep

# Turn this process into the i3 manager
exec i3
