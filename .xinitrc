#!/usr/bin/env sh

# set display size
# xrandr -s 800x600

# Test if config files are readable then load settings
[ -r "$HOME/.Xresources" ] && xrdb "$HOME/.Xresources"
#[ -r "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xdefaults"
#[ -r "$HOME/.Xmodmap" ]  && xmodmap "$HOME/.Xmodmap" # swap RCtrl and CapsLock

#setterm -blength 0 # remove beep

# Launch dbus for fcitx and perhaps pulse audio
# Not sure why this is -n and not -z
# TODO: Check on fresh install
#[ -n "$DBUS_SESSION_BUS_ADDRESS" ] && dbus-launch --sh-syntax --exit-with-session
#[ -n "$DBUS_SESSION_BUS_ADDRESS" ] && eval 'dbus-launch --sh-syntax --exit-with-session'

# Fcitx setup
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
killall fcitx; fcitx # Restart fcitx

exec i3
