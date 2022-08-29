#!/usr/bin/env sh
  # $0 <relative_or_absolute_path>
# Thanks to Rich (etalabs.net) for empty directory and filename tricks
#
# NOTE: ${PATH} and ${CDPATH} are separated by colons, can contain newlines, and
#       do not get escaped (.ie impossible to include directories with colons in
#       their name as part of ${PATH} and ${CDPATH})
#:!console c ~/named/
# ${PWD} vs `pwd` depends on how you want remembering symlinks followed handled

name="$( basename "$0"; printf a )"; name="${name%?a}"

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


# Settings
UI_FIELD_SEPARATOR='~'  # Do not use glob special characters (eg. '*')
DEBUG='true'



################################################################################
# Main
ENUM_LIST='1'
ENUM_INTERACTIVE='2'
ENUM_DEFAULT='0'
COMMAND="${ENUM_DEFAULT}"
FLAG_USE_FZF='true'

# Keep the side-effects contained to main
main() {
  # Dependencies
  require 'c.sh' || die 1 'FATAL' "Requires 'c.sh'"
  cdpath="$(c.sh cdpath)"
  profiling_start false

  # Options processing
  param=''; no_options='false'
  for arg in "$@"; do "${no_options}" || case "${arg}" in
    --)  no_options='true' ;;
    -h|--help)  show_help; exit 1 ;;
    -l|--list-aliases)    COMMAND="${ENUM_LIST}" ;;
    -i|--interactive)     COMMAND="${ENUM_INTERACTIVE}" ;;
    -p|--print|--no-fzf)  COMMAND="${ENUM_INTERACTIVE}"; FLAG_USE_FZF='false' ;;
    *)  [ -n "${param}" ] && { show_help; exit 2; }; param="${arg}"; ;;
  esac done

  # Branching
  profiling_start 'branch'
  case "${COMMAND}" in
    "${ENUM_DEFAULT}")      [ -z "${param}" ] && { show_help; exit 2; }
                            handle_path "${cdpath}" "${param}" ;;
    "${ENUM_LIST}")         find_shortcuts "${cdpath}" ;;
    "${ENUM_INTERACTIVE}")  display_shortcuts "${cdpath}" ;;
  esac
  profiling_mark "Done"
}

handle_path() {
  profiling_mark 'handle'
  shortcuts="$( find_shortcuts "${1}" )"
  path="${2}"

  profiling_mark 'branch on path'
  root="${path%%/*}"
  root_target="$( convert_shortcut "${shortcuts}" "${root}" )"
  {
    if [ -n "${root_target}" ]; then
      if [ "${path#*/*}" != "${path}" ]  # Ensure ${temp} has a '/'
        then temp="${path}"
        else temp="${path}/"
      fi
      printf %s "${root_target}/${temp#*/}"
    elif [ -n "${root}" ]; then  # Relative path
      dir="$(pwd -L; printf a)"; dir="${dir%?a}"
      printf %s/%s "${dir}" "${path}"  # if ${PWD} is root, will print '//'
    else  # Absolute
      printf %s "${path}"
    fi
    printf /a  # Perserve trailing newlines for after `awk`
  } | {  # Always will get an absolute path here
    profiling_mark 'awk simplify path'
    result="$(<&0 awk -v FS='' -v RS='' '{
      gsub(/\/\.\/(\.\/)*/, "/");         # Remove "./" sequences
      gsub("//*" , "/")                   # Remove "//" sequences

      # Check for ../.. eating itself unnecessary since always absolute paths
      while (sub("/[^/]*/\\.\\./", "/")); # Remove "../" sequences
      # Check for trailing ".." unnecessary since we always end with "a"

      # "/.."(/a) or "/."(/a) still gets through
      sub("^/\\.\\./?", "/");
      sub("^/\\./?", "/");

      printf("%s", $0);
    }')"
    result="${result%/a}"
    result="${result:-/}"  # If root, give back the singular slash
    printf %s "${result}"
  }
}

# Either dumps find
display_shortcuts()  {
  shortcuts="$( find_shortcuts "${1}" )"
  if "${FLAG_USE_FZF}" && require 'fzf'; then
    eval "set -- ${shortcuts}"

    separator=" ${UI_FIELD_SEPARATOR} /."
    choice="$(
      { while [ "$#" -gt 0 ]; do
        printf '%s%s%s\0' "${1}" "${separator}" "${2}"
        shift 2  # Should be a guarenteed 2
      done; } \
      | fzf --no-sort --read0 --no-multi --nth='1' --delimiter="${separator}"
    )" || exit "$?"
    choice="${choice%%${separator}*}"  # Safe if ${separator} glob-safe

    convert_shortcut "${shortcuts}" "${choice}"
  else
    puts "'${shortcuts} '" | awk -v FS="' '" -v RS="" '{
      for (i = 2; i < NF - 1; i += 2) {  # Do not need edge cases
        printf("'\''%s%s%s'\''\n", $(i), FS, $(i + 1));
      }
    }'
  fi
}

################################################################################
# Processing `c.sh cdpath`
# This is faster  than 1) doing an awk 2) processing without eval by using
# parameter substitution and skipping awk in find_shortcuts
convert_shortcut() {
  found_shortcuts="${1}"
  to_convert="${2}"
  eval "set -- ${found_shortcuts}"
  while [ "$#" -gt 0 ]; do
    [ "${1}" = "${to_convert}" ] && printf %s "${2}"
    shift 2  # Should be a guarenteed 2
  done
}
convert_shortcut1() {
  shortcut_list="${1#/./}"
  to_convert="${2}"
  while [ "${shortcut_list%*/./*}" != "${shortcut_list}" ]; do
    shortcut="${shortcut_list%%/./*}"; shortcut_list="${shortcut_list#*/./}"
    target="/${shortcut_list%%/./*}"; shortcut_list="${shortcut_list#*/./}"
    [ "${shortcut}" = "${to_convert}" ] && printf %s "${target}" && return 0
  done
  return 1
}

convert_shortcut2() {
  printf %s "${1}" | awk -v FS='/./' -v RS='' -v shortcut="${2}" '{
    for (i = 2; i < NF; i += 2) {
      if ($(i) == shortcut) printf("/%s", $(i + 1));
    }
  }'
}


find_shortcuts_fast() {
  cdlist="${1}:"
  while [ "${cdlist%*:*}" != "${cdlist}" ]; do
    dir="${cdlist%%:*}"
    cdlist="${cdlist#*:}"
    [ -d "${dir}" ] && for path in "${dir}"/* "${dir}"/.[!.]* "${dir}"/..?*; do
      if [ -L "${path}" ] && [ -d "${path}" ]; then
        cd "${path}" || die 1 'DEV' 'Should have been caught by if'
        base="${path##*/}"  # No need for `basename`, no trailing slash
        target="$( pwd -P; printf a )"; target="${target%?a}"
        printf /.%s "/${base}" "${target}"
      fi
    done
  done
}
find_shortcuts() {
  find_shortcuts_slow "${1}:"
}

# Output /.%s because only way to makes this paths parsable
find_shortcuts_slow() {
  cdlist="${1}:"
  { while [ "${cdlist%*:*}" != "${cdlist}" ]; do
    dir="${cdlist%%:*}"
    cdlist="${cdlist#*:}"
    [ -d "${dir}" ] && for path in "${dir}"/* "${dir}"/.[!.]* "${dir}"/..?*; do
      if [ -L "${path}" ] && [ -d "${path}" ]; then
        cd "${path}" || die 1 'DEV' 'Should have been caught by if'
        base="${path##*/}"  # No need for `basename`, no trailing slash
        target="$( pwd -P; printf a )"; target="${target%?a}"
        printf /.%s "/${base}" "${target}"
      fi
    done
  done; } | awk -v FS='/\\./' -v RS='' '
    function evalEscape(sTarget) {
      '"gsub(/'/, \"'\\\\''\", sTarget);"'
      return "'\''" sTarget "'\''";
    }
    {  # use "list" for checking uniqueness, only then print
      for (i = 2; i < NF; i += 2) {
        if (!list[$(i)]) {
          printf(" %s %s", evalEscape($(i)), evalEscape("/" $(i + 1)));
          list[$(i)] = 1;
        }
      }
    }
  '
}

################################################################################
# Helpers
require() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0
  done
  return 1
}
puts() { printf %s\\n "$@"; }
puterr() { printf %s\\n "$@" >&2; }
die() { c="$1"; puterr "$2: '${name}' -- $3"; shift 3; puterr "$@"; exit "$c"; }
eval_escape() { sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }


START_TIME=''
profiling_start() {
  START_TIME="$( date +%s%N )"
}
profiling_mark() {
  now="$( date +%s%N )"
  [ -z "${START_TIME}" ] && die 1 'DEV' 'did not run profile_start'
  PS4='DEV: + $((now - START_TIME)) ($LINENO) '
}

#profiling_start
#i=0
#profiling_mark
#echo $i
#while [ $i -lt 1000 ]; do i=$((i + 1)); true; done
##echo $i
#profiling_mark
#exit

#is_dir_and_empty() (
#  cd "$1" 2>/dev/null || { puterr "ERROR: Invalid \"$1\" in cdpath"; return 0; }
#  set -- .[!.]* ; test -e "$1" && return 1
#  set -- ..?* ; test -e "$1" && return 1
#  set -- * ; test -e "$1" && return 1
#  return 0
#)

main "$@"
