#!/usr/bin/env sh
  # $0 <relative_or_absolute_path>
# Thanks to Rich (etalabs.net) for empty directory and filename tricks
#
# TODO: Add rigorous portability to ${CDPATH}/'c.sh cdpath' parsing?
#       I am not even sure what ${PATH} parsing requirements are
# TODO: Check if examples are correct
# NOTE: ${PATH} and ${CDPATH} are separated by colons, can contain newlines, and
#       do not get escaped (.ie impossible to include directories with colons in
#       their name as part of ${PATH} and ${CDPATH})
#:!console c ~/named/
# ${PWD} vs `pwd` depends on how you want remembering symlinks followed handled


show_help() {
  name="${0##*/}"; cat >&2 <<EOF
SYNOPSIS
  ${name} PATH

DESCRIPTION
  Inspired by the folder aliases of zsh. And by the CDPATH of bash

  Prints the full path of PATH, if the relative link begins with an
  alias, then replace it with to what it aliases. Shortcuts are
  err "  specified by 'c.sh cdpath'.

  Prioritises the files in the \${PWD}

  err "  NOTE: Does not add a newline like 'pwd' does

OPTIONS
  -h, --help
    Display this help message

  -

NOTES
  Supports both relative and absolute links.

  Setup to have shortcuts setup as symlinks in the folder.

  This shortcut is evaluated to his physical link, but the any
  subdirectories after will be evaluated normally (for instance, bash
  perserves symlinks in its \${PWD}). In other words, the CDPATH
  will not be a constant part of the \${PWD} while still perserving
  other symlink history.

  \${CDPATH}/'c.sh cdpath' follows the same format as \${PATH}:
  Colon separates directories, so yes, multiple directories supported.
  However, this probably cannot handle to many strange characters in
  the cdpath.

EXAMPLES (Not sure these are even correct)
  Suppose 'c.sh cdpath' is "~/.config/alias"

  If "ln -s ~/.config/alias/scripts ~/.scripts/" then:
  err "    \$ cd \$(\${name} script/lib); pwd
    /home/.scripts/lib

  If  "ln -s ~/.config/alias/scripts ~/.scripts/"
  and "ln -s ~/.scripts/lib ~/.config/shared"
  err "    \$ cd \$(\${name} script/lib); pwd
    /home/.scripts/shared
EOF
}




# Main
main() {
  # Constants
  globals="${SCRIPTS}/c.sh"

  # Depenendency check
  [ -x "${globals}" ] || die "FATAL: Requires \"${globals}\""
  cdpath="$("${globals}" cdpath)"

  # Process parameters (only accept the first non-flag)
  target=""
  for arg in "$@"; do
    case "${arg}" in
      -h|--help)          show_help; exit 1 ;;
      -l|--list-aliases)  list_aliases "${cdpath}"; exit 0 ;;
      *)                  [ -z "${target}" ] && target="${arg}" ;;
    esac
  done
  [ -z "$target" ] && { show_help; exit 1; }



  # Main
  root="${target%%/*}"

  # Case 1: Found in the present working directory
  for node in ./*; do
    [ "./${root}" = "${node}" ] && { prints "$(pwd)/${target}"; exit 0; }
  done

  # Search the directories in cdpath for an alias that matches ${root}
  select_root() {
    # Exiting out of 'map_over_split_into_dirpaths' ends its subshell
    [ "${path##*/}" = "${root}" ] && { printf %s "${path}"; exit 0; }
  }
  search="$(map_over_split_into_dirpaths "${cdpath}" select_root; printf 'x')"
  search="${search%?}"

  # Case 2: Matches with an alias
  if [ -n "${search}" ]; then
    dest="$( follow_symlink_destination_aboslute_path_append_x "${search}")"
    dest="${dest%??}"  # It adds two characters to the path
    prints "${dest}${target#${root}}"

  # Case 3: Not associated with any alias
  else
    prints "${target}"
  fi
}

list_aliases() {
  cdpath="$1"

  print_alias() {
    path="$1"

    dest="$(follow_symlink_destination_aboslute_path_append_x "${path}")"
    dest="${dest%??}"
    puts "$(puts "${path##*/}" | eval_escape) -> '${dest}'"
  }
  map_over_split_into_dirpaths "${cdpath}" print_alias;
}


# Helpers
prints() { printf %s "$@"; }
puts() { printf %s\\n "$@"; }
puterr() { printf %s\\n "$@" >&2; }
eval_escape() { sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
die() { printf %s\\n "$@" >&2; exit 1; }

# 'pwd' adds a newline to strip while still maintaining trailing newlines
# so have to strip two characters
follow_symlink_destination_aboslute_path_append_x() {
  cd "$1" || die 'FATAL: Problem with symlink?'
  pwd -P
  printf 'x'
}


is_dir_and_empty() (
  cd "$1" 2>/dev/null || { puterr "ERROR: Invalid \"$1\" in cdpath"; return 0; }
  set -- .[!.]* ; test -e "$1" && return 1
  set -- ..?* ; test -e "$1" && return 1
  set -- * ; test -e "$1" && return 1
  return 0
)

# Subshell so this can be exited early
map_over_split_into_dirpaths() (
  cdpath="$1"
  cmd="$2"

  while [ -n "${cdpath}" ]; do
    dir="${cdpath%%:*}"
    if ! is_dir_and_empty "${dir}"; then
      for path in "${dir}"/*; do
        "${cmd}" "${path}"
      done
    fi

    cdpath="${cdpath#"${dir}"}"
    cdpath="${cdpath#:}"  # does nothing if it does not contain a colon
  done
)

main "$@"
