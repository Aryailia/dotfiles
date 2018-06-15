#!/bin/sh

# set display size
# xrandr -s 800x600

# Test if config files are readable then load settings
test -r $HOME/.Xresources && xrdb $HOME/.Xresources
#[ -r $HOME/.Xresources] && xrdb -merge $HOME/.Xdefaults

# remove beep
setterm -blength 0

# Set variables to use fcitx
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx

# Launch dbus for fcitx
test -z "$DBUS_SESSION_BUS_ADDRESS" || eval "$(dbus-launch --sh-syntax --exit-with-session)"

# Restart it
killall fcitx
fcitx

exec i3
