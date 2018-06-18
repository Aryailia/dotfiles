#!/bin/sh
# Symbolic links for all the config files
dotfiles="$HOME/dotfiles"
scripts="$dotfiles/.config/scripts/*"

for s in $scripts; do
  chmod 744 "$s"
done

[ ! -d "$HOME/.vim" ] && mkdir "$HOME/.vim"

list="
  .vim/custom
  .Xresources .tmux.conf .xinitrc .bash_profile .bashrc .inputrc
  .vim/vimrc .gtkrc-2.0 .streamlinkrc

  .config/i3 .config/scripts .config/gtk-3.0
  .config/wallpaper.jpg .config/mps-youtube/config .config/ranger/rc.conf
  .config/alacritty/alacritty.yml
"
for target in $list; do
  echo "$target"
  directory=${target%/*}
  # Make the parent directory if it does not exist
  [ "$target" != "$directory" ] && [ ! -d "$HOME/$directory" ] \
    && mkdir -p "$HOME/$directory"
  [ -n "$target" ] && rm -fr "${HOME:?}/$target"
  ln -s "$dotfiles/$target" "$HOME/$target"
done
