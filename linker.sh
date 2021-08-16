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
  ###
  # Constants
  # This script should be located at the outermost level of dotfiles directory
  me="$( realpath "$0"; printf a )"; me="${me%?a}"
  dotfiles="$( dirname "${me}"; printf a )"; dotfiles="${dotfiles%?a}"
  # Load constants (but not too many times), useful on initial install
  [ -z "${DOTENVIRONMENT}" ] && . "${dotfiles}/.profile"
  mkdir -p "${XDG_CONFIG_HOME}" "${XDG_CACHE_HOME}"

  # Global variables static to project (assume linker is ran in base directory)
  dotenv="${DOTENVIRONMENT}"
  ignore="${dotfiles}/.linkerignore.sh"
  ignore2="${dotenv}/.linkerignore.sh"
  scripts_relative_path=".config/scripts"
  make_shortcuts="${scripts_relative_path}/named-dirs.sh"
  vim_plugin_manager_save_path="${XDG_CONFIG_HOME}/nvim/autoload/plug.vim"
  vim_plugin_manager_link="$( puts \
    'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  )"

  ###
  # Parameters processing
  # Default case (initial run), does the options preprocessing
  # In case set by environment for some reason
  TARGET=""
  OVERWRITE=""
  VERBOSE=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help)  show_help; exit 0 ;;

      -c|--catious)  OVERWRITE="${ow_symlinks}" ;;
      -f|--force)    OVERWRITE="${ow_force}" ;;
      -i|--ignore)   OVERWRITE="${ow_do_not}" ;;
      -o|--output)   TARGET="$2"; shift 1 ;;
      -v|--verbose)  VERBOSE="true" ;;
    esac
    shift 1
  done

  # Set the defaults
  TARGET="${TARGET:-${HOME}}"
  OVERWRITE="${OVERWRITE:-0}"
  VERBOSE="${VERBOSE:-false}"

  [ -d "${TARGET}" ] || die 1 "FATAL: Invalid output directory '${TARGET}'"



  ###
  # Main
  puts "Special Case" "============"
  count="0"
  dotfile_ignore="$( "${ignore}" )"
  . "${ignore}" >/dev/null

  # Link some directories
  # Add trailing '/' for output message clarity
  # Also build up ${ignore}
  for dir in \
    "${scripts_relative_path}/" \
    '.config/snippets/' \
    '.config/nvim/after/' \
  ; do
    dotfile_ignore="${dotfile_ignore}$( escape "${dir}" )"
    symlink_relative_path "${dir}" && count="$(( count + 1 ))"
  done

  find "${dotfiles}/${scripts_relative_path}" -exec chmod 755 '{}' +
  if [ -x "${make_shortcuts}" ]; then
    if "${VERBOSE}"
      then "${make_shortcuts}"; puts "✓ Processed shortcuts"
      else "${make_shortcuts}" >/dev/null
    fi
    count="$(( count + 1 ))"
  else
    puts "! Shortcuts script '${make_shortcuts}' not found/executable"
  fi

  # Download vim plugin manager
  if [ -f "${vim_plugin_manager_save_path}" ]; then
     "${VERBOSE}" && puts "✓ Already downloaded vim plugin manager"
  else
    curl --create-dirs -fLo "${vim_plugin_manager_save_path}" \
      "${vim_plugin_manager_link}"
    puts "✓ Downloaded vim plugin manager"
  fi
  count="$(( count + 1 ))"
  puts "${count} files processed"  ""


  ###
  # Link other files
  puts "${dotfiles}" "======="
  list_relative_paths "${dotfiles}" "${dotfile_ignore}" \
    | from_link_to "${dotfiles}" "${TARGET}"

  # For personal files not to be uploaded to github
  puts "${dotenv}" "======="
  if [ -e "${dotenv}" ]; then
    list_relative_paths "${dotenv}" "$( "${ignore2}" )" \
      | from_link_to "${dotenv}" "${TARGET}"
  else
    puts '✗ ${DOTENVIRONMENT} does not exist'
  fi

  # To add more folders, just mimic this section and add the ignore file
}

################################################################################
# Main subfunctions

is_ignore() {
  ___target="$1"
  eval "set -- $2"
  #puts "test ${___target}"
  #printf 'yo |%s|\n' "${@}"
  for ___test in "$@"; do case "${___target}" in
    ${___test})   return 0 ;;
    ${___test}/)  return 0 ;;  # `list_relative_paths` adds '/' to ${___target}
    # When ${___test} has trailing slash but ${___target does not}
    ${___test}*)  [ "${___test}" != "${___test%/}" ] && return 0 ;;
  esac done
  return 1
}

NEWLINE='
'
list_relative_paths() {
  cd "$1" || die 1 "FATAL: \`list_relative_paths\` - \"$1\" does not exist"
  __list="${NEWLINE}././"  # Prefix all the files with ././ (last hh)
  while [ "${__list}" != "" ]; do  # Add limit to dodge infinite loop?
    __dir="${__list#${NEWLINE}}"
    __dir="${__dir%%${NEWLINE}././*}"
    __list="${__list#"${NEWLINE}${__dir}"}"

    for __f in "${__dir}"* "${__dir}".[!.]* "${__dir}"..?*; do
      [ ! -e "${__f}" ] && continue
      is_ignore "${__f}" "$2" && continue
      [ ! -L "${__f}" ] && [ -d "${__f}" ] \
        && __list="${__list}${NEWLINE}${__f}/"
      [ -f "${__f}" ] && puts "${__f}"
    done
  done
}

from_link_to() {
  [ -d "$1" ] || die 1 "FATAL: The source '$1' is invalid"
  [ -d "$2" ] || die 1 "FATAL: The destination '$2' is invalid"

  _list="${NEWLINE}$( cat - )"
  _count=0
  while [ "${_list}" != "" ]; do
    _count="$(( _count + 1 ))"
    _file="${_list#${NEWLINE}}"
    _file="${_file%%${NEWLINE}././*}"
    _list="${_list#"${NEWLINE}${_file}"}"
    _file="${_file#././}"

    symlink "$1/${_file}" "$2/${_file}" "${_file}"
  done
  puts "${_count} files processed"  ""
}

################################################################################
# Helpers
puts() { printf %s\\n "$@"; }
die() { exitcode="$1"; shift 1; printf %s\\n "$@" >&2; exit "${exitcode}"; }
require() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0
  done
  return 1
}

symlink_relative_path() {
  symlink "${dotfiles}/$1" "${TARGET}/$1" "$1"
}

# Really all I care about is removing trailing slashes
# And also protects from '/' -> '' case
# For use in `ln -s`, trailing slash is tacit keep same name (want to avoid)
normalise_path() {
  _dir="$( dirname "${1}"; printf a )"; _dir="${_dir%?a}"
  printf %s/%s\\n "${_dir}" "$( basename "${1}" )"
}

symlink() {
  source="$( normalise_path "${1}"; printf a )"; source="${source%?a}"
  target="$( normalise_path "${2}"; printf a )"; target="${target%?a}"
  name="${3}"

  [ -e "${source}" ] || die 1 "✗ FAIL: \"${source}\" does not exist"

  if [ "${OVERWRITE}" = "${ow_force}" ] \
    || [ "${OVERWRITE}" = "${ow_symlinks}" ] && [ -L "${target}" ]
  then
    rm -fr "${target}"
  fi

  if [ -e "${target}" ]; then
    # If is more safe than without (${VERBOSE} could be set by environment)
    if "${VERBOSE}"; then puts "! WARN: skipping without flags '${name}'"; fi
  else
    mkdir -p "${target%/*}"  # '/' is reserved on UNIX but not windows
    if [ -L "${source}" ]; then  # just copy relative symbolic links
      cp -P "${source}" "${target}" || die 1 "✗ FATAL: Unable to copy '${name}'"
    else  # otherwise make an absolute symbolic link
      ln -s "${source}" "${target}" || die 1 "✗ FATAL: Unable to link '${name}'"
    fi
    puts "✓ SUCCESS: '${name}'"
  fi
}

################################################################################
main "$@"
