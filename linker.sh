#!/usr/bin/env sh
  # Essentially replaces $dotfiles and $dotenv with $HOME via symlink
  # and chmods all files in the $scripts (files the subfolders of $scripts too)
  # and setups all named directories (directory aliases for c(d))
  # 
  # Will print ✗ on error and will exit prematurely. Indent for auto-detection
#
# The common approach is to git clone dotfiles into your $HOME directory, adding
# exceptions to ".gitignore" for each subfolder and direct file in $dotfiles
#
# I dislike the clutter of a "README.md" and other ".git"-related files in the
# already cluttered $HOME directory, so this workflow is designed so that you
# clones into a $dotfile directory (customisable), then execute this shellscript
# to symlink all the contents into $HOME. This also symlinks $dotenv to $HOME.
#
# Named directories are aliases useable by my custom change directory
# shellscript `c` or by the `cd` built-in in bash (via $CDPATH).
# Note: `c` and $CDPATH are not defined in this script
#
# This setup is intended to be:
# - portable across *nix systems (redox, debian, and void)
# - portable across Android with Termux
# - portable across Windows with git
# - portable across MacOS (currenttly without a test Mac, but it is unix-based)
# - easily deployable in a virtual machine environment
# - target bash, but sourceable with feature-parity to other shells (eg. ion)

# TODO: backup bookmarks?
# TODO: if folder is a symlink, it will delete the config file in dotfiles
# TODO: check for equality?

################################################################################
# Environment variables (customise to your environment)
dotfiles="$HOME/dotfiles"
scripts="$dotfiles/.config/scripts/**/* $dotfiles/.config/scripts/*"
dotenv="$DOTENVIRONMENT"
namedir="$HOME/.config/named_directories"

main() {
  ##############################################################################
  # Settings, the files to link over
  list="$(p '
    # Subdirecotires
    .vim/custom
    
    # Files
    .Xresources .tmux.conf .xinitrc .bash_profile .bashrc .inputrc .Xmodmap
    .vim/vimrc .gtkrc-2.0 .streamlinkrc .urlview
  ' | grep -v '^\s*#\|^$')"  # remove comments and blank lines
  
  # Files and subfolders in "$dotfiles/.config/"
  # These will be prefixed with ".config/": subdirectories, then files
  inconfig="$(p '
    aliases i3 scripts gtk-3.0 
  
    prompt.sh shellrc shell_profile
    wallpaper.jpg alacritty/alacritty.yml ion/initrc
    newsboat/config ranger/rc.conf mps-youtube/config 
  ' | grep -v '^\s*#\|^$')"  # remove comments and blank lines
  
  # Same concept but from $dotenv
  locales="$(p '
    .config/newsboat/urls
  ' | grep -v '^\s*#\|^$')"  # remove comments and blank lines
  
  # Will remove any symlinks contained in $namedir that are not in this hash
  symlink_hash="$(p "
    alias=$HOME/dotfiles/.config/aliases
    conf=$HOME/.config
    dfconf=$HOME/dotfiles/.config
    env=$HOME/.environment
    named=$HOME/.config/named_directories
    scripts=$HOME/dotfiles/.config/scripts
  
    dl=$HOME/Downloads
    projects=$HOME/projects
    wiki=$HOME/wiki
  " | grep -v '^\s*#\|^$')"  # remove comments and blank lines

  ##############################################################################
  # Code

  # Chmod all the custom scripts (and ones in subfolders for script helpers)
  for s in $scripts; do chmod 755 "$s"; done

  # Symlink all files and subfiles in $list directory into $HOME
  # ".config" treated differently to shorten $inconfig definition
  # Manual approach since the ".config" directory itself should not be symlinked
  # or else installing programs that put files into .config will put those files
  # into $dotfiles as well.
  p 'Directly in dotfiles' '===================='
  for target in $list; do install "$dotfiles" "$target"; done
  p '' 'Save typing for dotfiles/.config' '================================'
  for target in $inconfig; do install "$dotfiles" ".config/$target"; done

  # Symlinks for named directories, same logic as `install` but spread out
  # TODO: Just need to wrap this block in a loop to handle mutiple $namedir
  mkdir -p "$namedir" || { p "✗ mkdir \"$namedir\" error"; exit "$?"; }
  p '' 'Building named directory symlinks' '================================='
  # Remove any existing symlinks in the $namedir
  for name in "$namedir"/.[!.]* "$namedir"/* "$namedir"/..?*; do
    if file --mime-type "$name" | grep -q 'inode/symlink$'; then
      rm "$name" || { p "✗ rm \"$name\""; exit "$?"; }
      #p "← Removed $(basename "$name")"
    elif [ -e "$name"  ]; then
      p "✗ Not removing $name"
    fi
  done
  # Symlink as designated by $symlink_hash
  for keyvalue in $symlink_hash; do
    source="${keyvalue##*=}"
    target="$namedir/${keyvalue%=*}"
    p "$source → $(basename $target)"
    mkdir -p "$source" # in case they do not already exist
    ln -s "$source" "$target" || { p "✗ ln error"; exit "$?"; }
  done

  # Symlink all files and subfiles in $locales directory into $HOME
  p '' 'Not uploading these to github' '============================='
  for target in $locales; do install "$dotenv" "$target"; done
}


################################################################################
# Helpers
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
    p "✗ FAIL: $targetfrombase does not exist"
    exit 1 # design choice to not use return
  fi

  mkdir -p "$targetdirectory"  # Make the any directories if missing
  rm -fr "${HOME:?}/$targetfrombase" # :? prevents evaluation to '/'
  ln -s "$oldbase/$targetfrombase" "$HOME/$targetfrombase"
}

main
