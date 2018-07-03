#!/bin/sh
# Symbolic links for all the config files
dotfiles="$HOME/dotfiles"
scripts="$dotfiles/.config/scripts/*"

for s in $scripts; do
  chmod 744 "$s"
done

[ ! -d "$HOME/.vim" ] && mkdir "$HOME/.vim"

list="
  .vim/custom .named_directories
  
  .Xresources .tmux.conf .xinitrc .bash_profile .bashrc .inputrc
  .vim/vimrc .gtkrc-2.0 .streamlinkrc
"

inconfig="
  i3 scripts gtk-3.0 newsboat

  wallpaper.jpg mps-youtube/config ranger/rc.conf
  alacritty/alacritty.yml
"

install() {
  target=$1
  echo "$target"
  directory=${target%/*}
  # Make the parent directory if it does not exist
  [ "$target" != "$directory" ] && [ ! -d "$HOME/$directory" ] \
    && mkdir -p "$HOME/$directory"
  [ -n "$target" ] && rm -fr "${HOME:?}/$target"
  ln -s "$dotfiles/$target" "$HOME/$target"
}

for target in $list; do
  install "$target"
done

for target in $inconfig; do
  install ".config/$target"
done
