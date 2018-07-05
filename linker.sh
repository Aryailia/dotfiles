#!/usr/bin/env sh
# Symbolic links for all the config files
dotfiles="$HOME/dotfiles"
scripts="$dotfiles/.config/scripts/**/* $dotfiles/.config/scripts/*"
privatefiles="$HOME/privates"

# Chmod all the custom scripts
for s in $scripts; do
  chmod 744 "$s"
done

# The files to link over
list='
  .vim/custom .named_directories
  
  .Xresources .tmux.conf .xinitrc .bash_profile .bashrc .inputrc
  .vim/vimrc .gtkrc-2.0 .streamlinkrc
'

inconfig='
  i3 scripts gtk-3.0 newsboat

  wallpaper.jpg mps-youtube/config ranger/rc.conf
  alacritty/alacritty.yml
'
privates='
  .config/newsboat/urls
'

# Expects full paths, links everything into $HOME
install() {
  oldbase="$1"
  targetfrombase="$2"
  targetdirectory="$(dirname "$1/$2")"
 
  # consider permission validation checks
  if [ -e "$oldbase/$targetfrombase" ]; then # If file/directory exists
    printf '%s\n' "$targetfrombase"
  else
    printf '%s\n' "FAIL: $targetfrombase does not exist"
    exit 1 # design choice to not use return
  fi

  mkdir -p "$HOME/$targetdirectory"  # Make the any directories if missing
  rm -fr "${HOME:?}/$targetfrombase" # :? prevents evaluation to '/'
  ln -s "$oldbase/$targetfrombase" "$HOME/$targetfrombase"
}

printf 'Directly in dotfiles\n====================\n'
for target in $list; do install "$dotfiles" "$target"; done
printf '\nSave typing for dotfiles/.config\n================================\n'
for target in $inconfig; do install "$dotfiles" ".config/$target"; done
printf '\nNot uploading these to github\n=============================\n'
for target in $privates; do install "$privatefiles" "$target"; done
