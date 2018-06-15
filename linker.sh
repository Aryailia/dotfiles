#!/bin/sh
# Symbolic links for all the config files
DOTFILES=$HOME/dotfiles
SCRIPTS=$DOTFILES/.config/scripts/*

for S in $SCRIPTS; do
  chmod 744 $S
done

[ ! -d $HOME/.vim ] && mkdir $HOME/.vim

LIST="
  .vim/custom
  .vim/vimrc .Xresources .tmux.conf .xinitrc .bash_profile .gtkrc-2.0
  .config/i3 .config/scripts .config/gtk-3.0
  .config/wallpaper.jpg .config/mps-youtube/config
"
for target in $LIST; do
  echo "$target"
  directory=${target%/*}
  # Make the parent directory if it does not exist
  [ "$target" != "$directory" ] && [ ! -d $HOME/$directory ] \
    && mkdir -p $HOME/$directory
  [ -n "$target" ] && rm -fr "$HOME/$target"
  ln -s "$DOTFILES/$target" "$HOME/$target"
done
