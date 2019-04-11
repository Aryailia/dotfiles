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


show_help() {
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
    existing customisations.

  -f, --force
    Deletes the destination forcefully and symlinks. In particular, this is
    Useful if programs are run and the config files are already created in
    order to replace them with the dotfiles

  [-i], [--ignore]
    Does not replace with the symlink if the destination file already exists.
    The default behaviour and useful if you want to keep your current config

  -h, --help
    Display this help menu

  -o, --output DIRECTORY
    Changes the destination to which all the config files are symlinked
    Default is '${HOME}'

  -v, --verbose
    Mutes any warnings (ie. when symlinks are left alone because they already
    exist)
EOF
}


################################################################################
# Constants
ow_do_not="0"
ow_symlinks="1"
ow_force="2"




main() {
  # Global variables that are appropriate from the shell environment
  dotenv="${DOTENVIRONMENT}"

  # Global variables static to project (assume linker is ran in base directory)
  me="$(realpath "$0"; printf a)"; me="${me%??}"
  dotfiles="$(dirname "${me}"; printf a)"; dotfiles="${dotfiles%??}"
  ignore="${dotfiles}/.linkerignore.sh"
  ignore2="${dotenv}/.linkerignore.sh"
  scripts_relative_path=".config/scripts"
  # NOTE: Also see `run_with_env` for more global variables

  # Parameters processing
  # Help check
  for arg in "$@"; do case "${arg}" in
    -h|--help)  show_help; exit 0 ;;
    --)         break ;;
  esac done

  # Finite State Machine, all branches will exit
  fsm_state="$1"
  case "${fsm_state}" in
    1)  shift 1; filter_for_ignore 2 "${dotfiles}" "${ignore}";  exit "$?" ;;
    2)  shift 1; link_to_target    3 "${dotfiles}" "$@";         exit "$?" ;;
    3)  [ ! -x "${ignore2}" ] && run_with_env "${me} 5"  # run_with_env exits
        shift 1; filter_for_ignore 4 "${dotenv}"   "${ignore2}"; exit "$?" ;;
    4)  shift 1; link_to_target    5 "${dotenv}"   "$@";         exit "$?" ;;
    5)  shift 1; extras; exit ;;
  esac
  # Default case (initial run), does the options preprocessing
  set_options "$@"
}

################################################################################
# Branches of FSM

# Sets the environment variables to be used by `run_with_env`
set_options() {
  # In case set by environment for some reason
  TARGET=""
  OVERWRITE=""
  VERBOSE=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -c|--catious)  OVERWRITE="${ow_symlinks}" ;;
      -f|--force)    OVERWRITE="${ow_force}" ;;
      -i|--ignore)   OVERWRITE="${ow_do_not}" ;;
      -o|--output)   TARGET="$2"; shift 1 ;;
      -v|--verbose)  VERBOSE="true" ;;
      --)            break ;;
    esac
    shift 1
  done

  # Set the defaults
  TARGET="${TARGET:-${HOME}}"
  OVERWRITE="${OVERWRITE:-0}"
  VERBOSE="${VERBOSE:-false}"

  [ -d "${TARGET}" ] || die 1 "FATAL: Invalid output directory '${TARGET}'"
  run_with_env "${me} 1"
}

# Searches the directory '${files}' ignoring the files specified by '${ignore}'
filter_for_ignore() {
  next_fsm="$1"
  files="$2"
  ignore="$3"

  [ -x "${ignore}" ] \
    || die 1 "FATAL: Requires the shell script \"${ignore}\"." \
    "This just has to output a shell-quoted string (which can be blank)." \
    "Relative links and no unquoted newlines please"
  eval "set -- $(${ignore})"

  conditions=""
  for arg in "$@"; do
    conditions="${conditions} ! -path '${arg}'"
  done
  conditions="${conditions} \\( -type f -o -type l \\)"  # link or file

  cd "${files}" || die 1 "FATAL: dotfiles specified does not exist"
  run_with_env "find ./ ${conditions} -exec '${me}' '${next_fsm}' '{}' +"

  # Some debugging stuff
  #eval "find ./ ${conditions}" | awk '(1){print $0;} END{print NR;}'
  #puts "${conditions}"
}

# Symlinks relative paths from their a source "${origin}" to "${TARGET}"
link_to_target() {
  next_fsm="$1"
  origin="$2"   # BUG: Using 'source' as variable name + symlink using 'source'
  shift 2       #      does an append rather than an assignment

  [ -d "${origin}" ] || die 1 "FATAL: The source '${origin}' is invalid"
  [ -d "${TARGET}" ] || die 1 "FATAL: The destination '${TARGET}' is invalid"
  
  puts "${origin}" "===="
  for relative_path in "$@"; do
    rel="${relative_path#./}"
    symlink "${origin}/${rel}" "${TARGET}/${rel}" "${rel}"
  done
  puts "$# files processed"  ""
   
  run_with_env "${me} ${next_fsm}"
}

# The miscellaneous tasks
extras() {
  puts "Special Case" "============"
  symlink_relative_path "${scripts_relative_path}"
  find "${dotfiles}/${scripts_relative_path}" -exec chmod 755 '{}' +

  # Download it
  vim_plug="${HOME}/.config/nvim/autoload/plug.vim"
  [ -f "${vim_plug}" ] || curl -fLo "${vim_plug}" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  symlink_relative_path ".config/nvim/init.vim"
  symlink_relative_path ".config/nvim/vimrc"  # file structure links to init.vim
  symlink_relative_path ".config/nvim/after"
}


################################################################################
# Helpers
puts() { printf %s\\n "$@"; }
die() { exitcode="$1"; shift 1; printf %s\\n "$@" >&2; exit "${exitcode}"; }

run_with_env() {
  exec env \
    TARGET="${TARGET}" \
    OVERWRITE="${OVERWRITE}" \
    VERBOSE="${VERBOSE}" \
    sh -c "$*";
}

symlink_relative_path() {
  symlink "${dotfiles}/$1" "${TARGET}/$1" "$1" 
}

symlink() {
  source="$1"
  target="$2"
  name="$3"
  
  [ -e "${source}" ] || die 1 "✗ FAIL: \"${source}\" does not exist"

  if [ "${OVERWRITE}" = "${ow_force}" ] \
    || [ "${OVERWRITE}" = "${ow_symlinks}" ] && [ -L "${target}" ]
  then
    rm -f "${target}"
  fi

  if [ -e "${target}" ]; then
    # If is more safe than without (${VERBOSE} could be set by environment)
    if "${VERBOSE}"; then puts "! WARN: skipping without flags '${name}'"; fi
  else
    mkdir -p "${target%/*}"  # '/' is reserved on UNIX but not windows
    if [ -L "${source}" ]; then  # just copy relative symbolic links
      cp -P "${source}" "${target}" || die 1 "✗ FATAL: Unable to copy '${name}'"
    else  # otherwise make an aboslute symbolic link
      ln -s "${source}" "${target}" || die 1 "✗ FATAL: Unable to link '${name}'"
    fi
    puts "✓ SUCCESS: '${name}'"
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
#remove_hash_comments() { <&0 grep -v -e '^[ \t]*#' -e '^$'; }


main "$@"
