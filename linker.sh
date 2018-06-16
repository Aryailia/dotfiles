#!/bin/sh
# Symbolic links for all the config files
DOTFILES="$HOME/dotfiles"
scripts="$DOTFILES/.config/scripts/*"

for s in $scripts; do
  chmod 744 "$s"
done

[ ! -d "$HOME/.vim" ] && mkdir "$HOME/.vim"

list="
  .vim/custom
  .Xresources .tmux.conf .xinitrc .bash_profile .bashrc
  .vim/vimrc .gtkrc-2.0 .streamlinkrc

  .config/i3 .config/scripts .config/gtk-3.0
  .config/wallpaper.jpg .config/mps-youtube/config
"
for target in $list; do
  echo "$target"
  directory=${target%/*}
  # Make the parent directory if it does not exist
  [ "$target" != "$directory" ] && [ ! -d "$HOME/$directory" ] \
    && mkdir -p "$HOME/$directory"
  [ -n "$target" ] && rm -fr "${HOME:?}/$target"
  ln -s "$DOTFILES/$target" "$HOME/$target"
done
