#!/usr/bin/env sh
  # TODO: backup bookmarks?
# Symbolic links for all the config files
dotfiles="$HOME/dotfiles"
scripts="$dotfiles/.config/scripts/**/* $dotfiles/.config/scripts/*"
localfiles="$HOME/locales"
named_directories="$HOME/.config/named_directories"

# Chmod all the custom scripts
for s in $scripts; do
  chmod 744 "$s"
done

# The files to link over
list='
  .vim/custom
  
  .Xresources .tmux.conf .xinitrc .bash_profile .inputrc .Xmodmap
  .vim/vimrc .gtkrc-2.0 .streamlinkrc .urlview
'

inconfig='
  aliases i3 scripts gtk-3.0 

  prompt.sh shellrc shell_profile
  wallpaper.jpg newsboat/config ranger/rc.conf mps-youtube/config 
  alacritty/alacritty.yml 
'
locales='
  .config/newsboat/urls
'
symlink_hash="
  alias=$HOME/dotfiles/.config/aliases
  dfconf=$HOME/dotfiles/.config
  conf=$HOME/.config
  named=$HOME/.config/named_directories
  scripts=$HOME/dotfiles/.config/scripts

  dl=$HOME/Downloads
  projects=$HOME/projects
  wiki=$HOME/wiki
"



################################################################################
# Code

p() { printf '%s\n' "$@"; }
# Expects full paths, links everything into $HOME
install() {
  oldbase="$1"
  targetfrombase="$2"
  targetdirectory="$(dirname "$HOME/$2")"
 
  # consider permission validation checks
  if [ -e "$oldbase/$targetfrombase" ]; then # If file/directory exists
    p "$targetfrombase"
  else
    p "FAIL: $targetfrombase does not exist"
    exit 1 # design choice to not use return
  fi

  mkdir -p "$targetdirectory"  # Make the any directories if missing
  rm -fr "${HOME:?}/$targetfrombase" # :? prevents evaluation to '/'
  ln -s "$oldbase/$targetfrombase" "$HOME/$targetfrombase"
}

p 'Directly in dotfiles' '===================='
for target in $list; do install "$dotfiles" "$target"; done
p '' 'Save typing for dotfiles/.config' '================================'
for target in $inconfig; do install "$dotfiles" ".config/$target"; done
p '' 'Not uploading these to github' '============================='
for target in $locales; do install "$localfiles" "$target"; done

# Symlinks for named directories
mkdir -p "$named_directories"
p '' 'Linking' '======='
for keyvalue in $symlink_hash; do
  source="${keyvalue##*=}"
  target="$named_directories/${keyvalue%=*}"
  p "$source"
  mkdir -p "$source" # in case they do not already exist
  rm --force "$target"
  ln --symbolic "$source" "$target" 
done
