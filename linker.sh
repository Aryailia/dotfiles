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
# TODO: Check if foward-slash is reserved character on MSYGIT (windows)


show_help_and_exit() {
  name="${me}"
  <<EOF cat >&2
SYNOPSIS
  ${name} [OPTION]
  # ${name} [OPTION] DESTINATION (Not supported yet)
  # ${name} STATE_NUMBER (not meant for external use)

DESCRIPTION
  This deploys the dotfiles out. Designed so that the dotfiles can be directly
  cloned and all the configs as neded by programs can follow symlinks to the
  dotfiles folder and used regularly. Currently only reads the first parameter

  Symlinks everything form \${dotfiles} to \${destination} (default \${HOME}).

  Scripts are treated specially (may want to treat vim's folder specially too)
  because when creating new scripts, want them to be immediately useable and
  not require the user to run linker to have them show up.

  You can choose how to handle replacing files that already exist with the flags

  A custom \${destination} is not supported yet (just change it manually)

  The third form is not meant for use externally

OPTIONS
  -c, --catious
    Only replaces symlinks if the destination files are they themselves
    symlinks. Useful if directory changes occured and don't want to destroy
    existing customisations. (This is not supported as of yet, due to there
    not being a way to scan for symlinks because 'file' is not found on
    termux (android) setups by default and have not decided on the solution)

  -f, --force
    Deletes the destination forcefully and symlinks. Useful if 

  [-i], [--ignore]
    Does not delete the 

  -h, --help
    Display this help menu

EOF
  exit 1
}


################################################################################
# Constants
ow_do_not="0"
ow_symlinks="1"
ow_force="2"



################################################################################
# Environment variables (customise to your environment)
dotfiles="${HOME}/dotfiles"
me="${dotfiles}/$(basename "$0"; printf a)"; me="${me%??}"
destination="${HOME}"
scripts_relative_path=".config/scripts"
#dotenv="${DOTENVIRONMENT}"
#namedir="${HOME}/.config/named_directories"
ignore="${dotfiles}/.linkerignore.sh"



main() {
  fsm_state="${1}"; [ "$#" -gt 0 ] && shift 1
  
  case "${fsm_state}" in
    -h|--help)     show_help_and_exit ;;


    -c|--catious) # OVERWRITE="${ow_symlinks}" process_ignores 2 ;;
                   die 'Currently not supported' ;;
    -f|--force)    OVERWRITE="${ow_force}"    process_ignores 2 "${ignores}" ;;
    -i|--ignore)   OVERWRITE="${ow_do_not}"   process_ignores 2 "${ignores}" ;;

    2)  link_to_dotfiles_from_home 3 "$@" ;;
       #process_ignores 2 "${}";;
    3)  extras 4 ;;
    4)  link_to_dotfiles_from_home 5 "$@" ;;
    5)  ;;

    *)              OVERWRITE="${ow_do_not}"   process_ignores 2 "${ignores}" ;;
  esac
}

extras() {
  ctrl="OVERWRITE='${OVERWRITE}'"
  next_fsm="$1"

  puts "" "Special Case" "============"
  symlink "${dotfiles}/${scripts_relative_path}" \
    "${destination}/${scripts_relative_path}" "${scripts_relative_path}"
  find "${dotfiles}/${scripts_relative_path}" -exec chmod 755 '{}' +

  vim_plug="${HOME}/.vim/autoload/plug.vim"
  [ -f "${vim_plug}" ] || curl -fLo "${vim_plug}" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  p=".vim/vimrc";   symlink "${dotfiles}/${p}" "${destination}/${p}" "${p}"

  symlink "${dotfiles}/.vim/after" \
    "${destination}/.vim/after" "./.vim/after"

  # Include all the folders in ${p}, excluding ${p} itself
  #cd "${dotfiles}" || die "FATAL: dotfiles specified does not exist"
  #p="./.vim/plugin"
  #find "${p}" ! -path "${p}" -type d -exec "${me}" "${next_fsm}" '{}' +
}

process_ignores() {
  ctrl="OVERWRITE='${OVERWRITE}'"
  next_fsm="$1"

  [ -x "$ignore" ] \
    || die "FATAL: Requires the shell script \"${ignore}\"." \
    "This just has to output a shell-quoted string (which can be blank)." \
    "Relative links and no unquoted newlines please"
  eval "set -- $(${ignore})"

  condtions=""
  for arg in "$@"; do
    conditions="${conditions} ! -path '${arg}'"
  done
  conditions="${conditions} \\( -type f -o -type l \\)"  # link or file

  cd "${dotfiles}" || die "FATAL: dotfiles specified does not exist"
  eval "${ctrl} find ./ ${conditions} -exec '${me}' '${next_fsm}' '{}' +"

  # Some debugging stuff
  #eval "find ./ ${conditions}" | awk '(1){print $0;} END{print NR;}'
  #puts "${conditions}"
}

link_to_dotfiles_from_home() {
  #ctrl="OVERWRITE='${OVERWRITE}'"
  next_fsm="$1"; shift 1
  [ -d "${destination}" ] || die "FATAL: ${destination} is invalid"
  
  # Some debugging stuff
  #puts "$@" | awk '(1){print $0;} END{print NR;}'
  #exit

  for relative_path in "$@"; do
    rel="${relative_path#./}"
    symlink "${dotfiles}/${rel}" "${destination}/${rel}" "${rel}"
  done
   
  OVERWRITE="${OVERWRITE}" "${me}" "${next_fsm}"
}

symlink() {
  #OVERWRITE="${OVERWRITE}"
  source="$1"
  target="$2"
  name="${3:-${target}}"
  
  [ ! -e "${source}" ] && die "✗ FAIL: \"${source}\" does not exist"

  if [ "${OVERWRITE}" = "${ow_force}" ] \
    #|| [ "${OVERWRITE}" = "${ow_symlinks}" ] \
    #&& { file --mime-type "${target}" | grep -q 'inode/symlink$' } 
  then
    rm -f "${target}"
  fi

  if [ -e "${target}" ]; then
    puts "! WARN: skipping without flags \"${name}\""
  else
    mkdir -p "${target%/*}"  # '/' is reserved on UNIX but not windows
    ln -s "${source}" "${target}" || die "✗ FATAL: Unable to link \"${name}\""
    puts "✓ SUCCESS: \"${name}\""
  fi
}

#blah() {
#  # Same concept but from $dotenv
#  locales="$(puts '
#    .config/newsboat/urls
#  ' | remove_hash_comments)"
#  
#  # Will remove any symlinks contained in $namedir that are not in this hash
#  symlink_hash="$(puts "
#    alias=$HOME/dotfiles/.config/aliases
#    conf=$HOME/.config
#    dfconf=$HOME/dotfiles/.config
#    env=$HOME/.environment
#    named=$HOME/.config/named_directories
#    scripts=$HOME/dotfiles/.config/scripts
#  
#    dl=$HOME/Downloads
#    projects=$HOME/projects
#    wiki=$HOME/wiki
#  " | remove_hash_comments)"
#
#  ##############################################################################
#  # Code
#
#  # Chmod all the custom scripts (and ones in subfolders for script helpers)
#}


################################################################################
# Helpers
puts() { printf '%s\n' "$@"; }
die() { printf %s\\n "$@" >&2; exit 1; }
#remove_hash_comments() { <&0 grep -v -e '^[ \t]*#' -e '^$'; }


main "$@"
