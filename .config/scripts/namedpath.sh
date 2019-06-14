#!/usr/bin/env sh
  # $0 <relative_or_absolute_path>
# Thanks to Rich (etalabs.net) for empty directory and filename tricks
#
# NOTE: ${PATH} and ${CDPATH} are separated by colons, can contain newlines, and
#       do not get escaped (.ie impossible to include directories with colons in
#       their name as part of ${PATH} and ${CDPATH})
#:!console c ~/named/
# ${PWD} vs `pwd` depends on how you want remembering symlinks followed handled

name="$(basename "$0"; printf a)"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
USAGE
  ${name} [OPTION] PATH

DESCRIPTION
  Inspired by the folder aliases of zsh. And by the \${CDPATH} of bash

  Translates PATH into an absolute path by referencing \`c.sh cdpath\`.
  Shortcuts found within this 'cdpath' are evaluated to physical locations
  (without keeping the trace of symlinks), otherwise paths are evaluated
  logically.

  Shortcuts are prioritised over items in the \${PWD}. Prefix with './' if you
  want to access items in the current directory.

  Eg.
    'a' is a shortcut to '/hello' and there is a directory \`./a\`
    \`namedpath.sh a\` will print '/hello', not 'a' or './a'


  NOTE: Intentionally Does not add a newline like 'pwd' does
  NOTE: '~' is not expanded as this is the job of the shell (if unquoted)

OPTIONS
  -h, --help
    Display this help message

  -l, --list-aliases
    Gives a list of shortcuts and the location they link to

NOTES
  Supports both relative and absolute links for PATH.

  Does not print a trailing forward slash

  Setup to have shortcuts setup as symlinks in the folder.

  \${CDPATH}/'c.sh cdpath' follows the same format as \${PATH}:
  Colon separates directories, so yes, multiple directories supported.
  However, this probably cannot handle to many strange characters in
  the cdpath.

EXAMPLES
  Suppose 'c.sh cdpath' is "~/.config/named_directories"

  Eg. 1
  \`ln -s ~/.config/named_directories/s ~/.scripts/\`
  \`cd "\$(${name} s/lib)"\`
  \`pwd -L\`
    /home/.scripts/lib

  Eg. 2
  \`ln -s ~/.config/named_directories/scripts ~/.scripts/\`
  \`ln -s ~/.scripts/lib ~/.config/shared\`
  \`cd "\$(${name} script/lib)"\`
  \`pwd -L\`
    /home/.scripts/lib
  \`cd ~/.scripts/lib\`
  \`pwd -L\`
    /home/.scripts/lib
  \`pwd -P\`
    /home/.scripts/shared
EOF
}



main() {
  # Dependencies
  command -v c.sh >/dev/null 2>&1 || die "FATAL: Requires \"${globals}\""
  cdpath="$(c.sh cdpath)"

  # Options processing
  args=''; no_options='false'
  for arg in "$@"; do "${no_options}" || case "${arg}" in
    --)  no_options='true' ;;
    -h|--help)  show_help; exit 1 ;;
    -l|--list-aliases)  list_aliases "${cdpath}"; exit 1 ;;
    *)   args="${args} $(puts "${arg}" | eval_escape)" ;;
  esac done

  [ -z "${args}" ] && { show_help; exit 2; }
  eval "set -- ${args}"

  path="$1"
  {
    root="${path%%/*}"
    if     [ "${root}" != '.' ] && [ "${root}" != '..' ] \
        && [ -L "${cdpath}/${root}" ]
    then
      cd "${cdpath}/${root}" || die 'FATAL: Problem with symlink?'
      dir="$(pwd -P; printf a)"; dir="${dir%?a}"  # Physical
      printf %s "${dir}"

      # Delete this link from ${path}
      # Add '/' suffix to deal with inputs of just the shortcut eg. $1='a'
      [ "${path%/}" = "${path}" ] && path="${path}/"
      path="${path#*/}"
    else
      dir="$(pwd -L; printf a)"; dir="${dir%?a}"  # Logical
      printf %s "${dir}"
    fi
    printf '/%s' "${path}"

  } | {
    # Awk does not preserve trailing newlines so cannot pipe to awk
    result="$(</dev/null awk -v a="$(cat -; printf a)" 'END{
      gsub(/\/\.\/(\.\/)*/, "/", a);         # Remove "./" sequences
      gsub("//*" , "/", a)                   # Remove "//" sequences
      # Do not have to check for ../.. eating itself since always absolute paths
      while (sub("/[^/]*/\\.\\./", "/", a)); # Remove "../" sequences
      sub("/[^/]*/\\.\\.$", "/", a);         # Remove ".." ending sequence

      # "/.." or "/." still gets through
      sub("^/\\.\\./?$", "/", a);
      sub("^/\\./?$", "/", a);

      # Remove trailing slash
      if (a != "/")    sub("/$", "", a);
      printf("%s", a);
    }')"
    result="${result%a}"
    printf %s "${result%a}"
  }
}

# Output /.%s because only way to makes this paths parsable
list_aliases() {
  # Want the word splitting
  find -H $(printf %s "$1:" | sed 's|:|/.\n|g') ! -name '.' -prune \
    -exec sh -c '
      [ -h "$1" ] && [ -d "$1" ] && cd "$1" || exit
      dir="$(pwd -P; printf a)"; dir="${dir%?a}"
      printf "\"%s\" ~ /.%s\n" "${1##*/}" "${dir}"
    ' _ {} \;
}


# Helpers
puts() { printf %s\\n "$@"; }
puterr() { printf %s\\n "$@" >&2; }
eval_escape() { sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
die() { printf %s\\n "$@" >&2; exit 1; }


#is_dir_and_empty() (
#  cd "$1" 2>/dev/null || { puterr "ERROR: Invalid \"$1\" in cdpath"; return 0; }
#  set -- .[!.]* ; test -e "$1" && return 1
#  set -- ..?* ; test -e "$1" && return 1
#  set -- * ; test -e "$1" && return 1
#  return 0
#)

main "$@"
