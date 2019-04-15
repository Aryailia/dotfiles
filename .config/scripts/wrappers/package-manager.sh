#!/usr/bin/env sh

show_help() {
  name="$(basename "$0"; printf a)"; name="${name%??}"
  <<EOF cat - >&2
SYNOPSIS
  ${name} [OPTIONS] [PKG1 [PKG2 [...]]]

DESCRIPTION

OPTIONS
  -x,--target   PACKAGE_MANAGER   Specify a package manager

  -E,--edit                       Edit
  -C,--reconfigure                WIP
  -I,--install                    Install packages
  -Q,--query                      Exit
  -R,--remove                     Exit

  -e,--extenral                   Sync local and external repository
  -f,--force                      WIP, force version numbers?
  -h,--help                       Display help
  -s,--source                     Use source compiler

  -1,--single                     Limit to just one, or without dependencies
  -m,--manual                     Stuff
  -o,--orphans                    Stuff

  -d,--dependents                 Stuff
  -i,--info                       Stuff
  -p,--print                      Stuff
  -r,--reverse-dependents         Stuff
  -
EOF
}


ENUM_TRUE=0
ENUM_FALSE=1

ENUM_EDIT=1
ENUM_INSTALL=2
ENUM_QUERY=3
ENUM_REMOVE=4
ENUM_RECONFIG=5

main() {
  # Flags
  TARGET=""

  FLAG_SINGLE='false'
  FLAG_FORCE='false'
  FLAG_HELP='false'
  FLAG_INFO='false'
  FLAG_MANUAL='false'
  FLAG_ORPHANS='false'
  FLAG_PRINT='false'
  FLAG_SOURCE='false'
  FLAG_SYNC='false'

  FLAG_SEARCH_DEPENDENTS='false'
  FLAG_SEARCH_REVERSE_DEPENDENTS='false'

  # Dependencies
  _SUDO="$([ "$(uname -o)" != "Android" ] && prints "sudo")"

  # Options processing
  args=""
  no_options="false"
  while [ "$#" -gt 0 ]; do
    if ! "${no_options}"; then
      # Split grouped single-character arguments up, and interpret '--'
      # Parsing '--' here allows "invalid option -- '-'" error later
      opts=""
      case "$1" in
        --)      no_options="true"; shift 1; continue ;;
        -[!-]*)  opts="${opts}$(puts "${1#-}" | sed 's/./ -&/g')" ;;
        *)       opts="${opts} $1" ;;
      esac

      # Process arguments properly now
      for entry in ${opts}; do case "${entry}" in
        -x|--target)  TARGET="$2"; shift 1 ;;

        -E|--edit)         COMMAND="${ENUM_EDIT}" ;;
        -D|--debug)        COMMAND="${ENUM_RECONFIG}" ;;
        -I|--install)      COMMAND="${ENUM_INSTALL}" ;;
        -Q|--query)        COMMAND="${ENUM_QUERY}" ;;
        -R|--remove)       COMMAND="${ENUM_REMOVE}" ;;

        -e|--extenral)            FLAG_SYNC='true' ;;
        -f|--force)               FLAG_FORCE='true' ;;
        -h|--help)                FLAG_HELP='true' ;;
        -s|--source)              FLAG_SOURCE='true' ;;

        -1|--single)              FLAG_SINGLE='true' ;;
        -m|--manual)              FLAG_MANUAL='true' ;;
        -o|--orphans)             FLAG_ORPHANS='true' ;;

        -d|--dependents)          FLAG_SEARCH_DEPENDENTS='true' ;;
        -i|--info)                FLAG_INFO='true' ;;
        -p|--print)               FLAG_PRINT='true' ;;
        -r|--reverse-dependents)  FLAG_SEARCH_REVERSE_DEPENDENTS='true' ;;

        # Put argument checks above this line (for error detection)
        -[!-]*)  show_help; die 1 "FATAL: invalid option '${entry-}'" ;;
        *)       args="${args} $(puts "$1" | eval_escape)"
      esac done
    else
      args="${args} $(puts "$1" | eval_escape)"
    fi
    shift 1
  done

  #[ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"

  case "${COMMAND}" in
    "${ENUM_EDIT}")      echo edit ;;
    "${ENUM_INSTALL}")   package_install "$@" ;;
    "${ENUM_QUERY}")     package_query "$@" ;;
    "${ENUM_REMOVE}")    package_remove "$@" ;;
    "${ENUM_RECONFIG}")  echo reconfig ;;
    *)  show_help; exit "$(if "${FLAG_HELP}"; then print 1; else 1; fi)" ;;
  esac
}

match_manager() {
  case "${TARGET}" in
    pip|python)      [ "$1" = "pip" ] ;;
    cargo|rust)      [ "$1" = "cargo" ] ;;
    void|voidlinux)  require xbps-install ;;
    ?*)  die 1 "FATAL: Not recongized -- '${TARGET}'" ;;
    *)   true ;;
  esac
}


help_install() {
  name="$(basename "$0"; printf a)"; name="${name%??}"
  <<EOF cat - >&2
USAGE: ${name} -I  [OPTIONS]
  -s


EOF
}

# Note on using force to install a specific version of a package
package_install() {
  if "${FLAG_HELP}"; then
    help_install
  fi
  if match_manager void && require xbps-install; then
    cmd="$(if "${FLAG_SOURCE}"
      then prints xbps-source
      else prints xbps-install
    fi)"
    options="$(
      "${FLAG_SYNC}" && prints "S"
      "${FLAG_FORCE}" && prints "f"
      "${FLAG_MANUAL}" && prints "u"
    )"
    if [ -n "${options}" ]
      then _print "${_SUDO}" "${cmd}" "-${options}" "$@"
      else _print "${_SUDO}" "${cmd}" "$@"
    fi
  fi

  if match_manager arch && require pacman; then
    options="$(
      "${FLAG_SYNC}" && prints "S"
      prints "y"
      #"${FLAG_FORCE}" && prints "y"
      "${FLAG_MANUAL}" && prints "u"
    )"
    if [ -n "${options}" ]
      then _print "${_SUDO}" pacman "-${options}" "$@"
      else _print "${_SUDO}" pacman "$@"
    fi
  fi

  # Forgot how apt-get works, so skipping for now
  if match_manager debian && { require apt || require apt-get; }; then
    "${FLAG_SYNC}" && _print "${_SUDO}" apt update
    "${FLAG_MANUAL}" && _print "${_SUDO}" apt upgrade
    #"${FLAG_FORCE}" && _print "${_SUDO}"
  fi
}

package_query() {
  if match_manager void && require xbps-query; then
    will_post_process="$(if "${FLAG_INFO}" \
        || "${FLAG_SEARCH_DEPENDENTS}" || "${FLAG_SEARCH_REVERSE_DEPENDENTS}"
      then prints "${ENUM_TRUE}"
      else prints "${ENUM_FALSE}"
    fi)"

    { { if "${FLAG_ORPHANS}"; then   xbps-query -O
        #elif "${FLAG_LOCKS}"; then
        elif "${FLAG_MANUAL}"; then  xbps-query -m
        elif "${FLAG_SYNC}"; then
          xbps-query -Rs '.' | do_if "${will_post_process}" cut -d ' ' -f 2
        else
          xbps-query -s '.'  | do_if "${will_post_process}" cut -d ' ' -f 2
        fi

        # Want the splitting for grep
      } | { [ "$#" -gt 0 ]; do_if "$?" grep -i $(printf -- ' -e %s' "$@")
      } | { "${FLAG_SINGLE}"; do_if "$?" sed 1q;
      } | {
        if "${FLAG_SEARCH_DEPENDENTS}"; then
          xargs -n 1 xbps-query -x | sort | uniq
        elif "${FLAG_SEARCH_REVERSE_DEPENDENTS}"; then
          xargs -n 1 xbps-query -X | sort | uniq
        elif "${FLAG_INFO}"; then
          xargs -n 1 xbps-query -S
        else
          cat -
        fi
      }
    }
  fi
}

# Use ${ORPHANS} for autoremove? or use for cleanup method?
package_remove() {
  if match_manager void && require xbps-remove; then
    options="$(
      "${FLAG_SINGLE}" || prints "R"
      "${FLAG_FORCE}" && prints "f"
      "${FLAG_ORPHANS}" && prints "o"
    )"
    if [ -n "${options}" ]
      then _print "${_SUDO}" xbps-remove "-${options}" "$@"
      else _print "${_SUDO}" xbps-remove "$@"
    fi
  fi

  if match_manager pip && require pip; then
    die 1 'WIP'
    #options="$(
    #  "${FLAG_SINGLE}" || prints "r"
    #)"
    #if [ -n "${options}" ]
    #  then _print "${_SUDO}" pip uninstall "-${options}" "$@"
    #  else _print "${_SUDO}" pip uninstall "$@"
    #fi
  fi
}


# Helpers
puts() { printf %s\\n "$@"; }
prints() { printf %s "$@"; }
die() { exitcode="$1"; shift 1; printf %s\\n "$@" >&2; exit "${exitcode}"; }
require() { command -v "$1" >/dev/null 2>&1; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

_print() {
  if "${FLAG_PRINT}"; then
    cmd="$(for a in "$@"; do prints "$(puts "$a" | eval_escape) "; done)"
    prints "${cmd% }"
  else
    "$@"
  fi
}

do_if() {
  if [ "$1" = "${ENUM_TRUE}" ]
    then shift 1; "$@"
    else          <&0 cat -
  fi
}

main "$@"
