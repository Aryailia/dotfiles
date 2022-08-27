See https://wiki.archlinux.org/title/XDG_Autostart

# Services

However, I am also putting in services that should be managed by the init process.
These should not go in `$HOME/.xprofile` because these should be run even in a non-graphical environment.
These should not go in `$HOME/.profile` because you do not want them running every time you start a new bash shell.
