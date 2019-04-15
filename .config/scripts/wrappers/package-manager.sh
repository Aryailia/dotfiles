#!/usr/bin/env sh

show_help() {
  name="$(basename "$0"; printf a)"; name="${name%??}"
  <<EOF cat - >&2
SYNOPSIS
  ${name} [OPTIONS] [PKG1 [PKG2 [...]]]

DESCRIPTION

OPTIONS
  -x,--target   PACKAGE_MANAGER   Specify a package manager

  -E,--edit                Edit
  -C,--reconfigure         WIP
  -I,--install             Install packages
  -Q,--query               Exit
  -R,--remove              Exit

  $(flag SYNC BOTH    )            Sync local and external repository
  $(flag FORCE BOTH)               WIP, force version numbers?
  $(flag HELP BOTH)                Display help
  $(flag QUIET BOTH)               Mutes some explaination text
  $(flag SOURCE BOTH)              Use source compiler

  $(flag SINGLE BOTH)              Limit to just one, or without dependencies
  $(flag MANUAL BOTH)              Stuff
  $(flag ORPHANS BOTH)             Stuff

  $(flag DEPENDENTS BOTH)          Stuff
  $(flag INFO BOTH)                Stuff
  $(flag PRINT BOTH)               Stuff
  $(flag PROVIDESFOR BOTH       )  Stuff
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
  flag all SET 'false'

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

        "$(flag SYNC MIN)"|"$(flag SYNC FUL)")        flag SYNC SET 'true' ;;
        "$(flag FORCE MIN)"|"$(flag FORCE FUL)")      flag FORCE SET 'true' ;;
        "$(flag HELP MIN)"|"$(flag HELP FUL)")        flag HELP SET 'true' ;;
        "$(flag QUIET MIN)"|"$(flag QUIET FUL)")      flag QUIET SET 'true' ;;
        "$(flag SOURCE MIN)"|"$(flag SOURCE FUL)")    flag SOURCE SET 'true' ;;

        "$(flag SINGLE MIN)"|"$(flag SINGLE FUL)")    flag SINGLE SET 'true' ;;
        "$(flag MANUAL MIN)"|"$(flag MANUAL FUL)")    flag MANUAL SET 'true' ;;
        "$(flag ORPHANS MIN)"|"$(flag ORPHANS FUL)")  flag ORPHANS SET 'true' ;;

        "$(flag INFO MIN)"|"$(flag INFO FUL)")        flag INFO SET 'true' ;;
        "$(flag PRINT MIN)"|"$(flag PRINT FUL)")      flag PRINT SET 'true' ;;
        "$(flag DEPENDENTS MIN)"|"$(flag DEPENDENTS FUL)")
          flag DEPENDENTS SET 'true' ;;
        "$(flag PROVIDESFOR MIN)"|"$(flag PROVIDESFOR FUL)")
          flag PROVIDESFOR SET 'true' ;;

        # Put argument checks above this line (for error detection)
        -[!-]*)  show_help; die 1 "FATAL: invalid option '${entry-}'" ;;
        *)       args="${args} $(puts "$1" | eval_escape)"
      esac done
    else
      args="${args} $(puts "$1" | eval_escape)"
    fi
    shift 1
  done

  match_manager "${TARGET}"  # Check

  #[ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"

  case "${COMMAND}" in
    "${ENUM_EDIT}")      echo WIP ;;
    "${ENUM_INSTALL}")   package_install "$@" ;;
    "${ENUM_QUERY}")     package_query "$@" ;;
    "${ENUM_REMOVE}")    package_remove "$@" ;;
    "${ENUM_RECONFIG}")  echo WIP ;;
    *)  show_help; exit "$(if flag HELP GET; then print 1; else 1; fi)" ;;
  esac
}

handle() {
  case "$2" in
    MIN)   prints "$3" ;;
    FUL)   prints "${4%% *}" ;;
    BOTH)  prints "$3,$4" ;;
    SET)   eval "FLAG_$1='$5'" ;;
    GET)   eval "\${FLAG_$1}" ;;
    UNSUPPORTED)
      name="$(basename "$0"; printf a)"; name="${name%??}"
      die 1 "FATAL: \$(${name} -x '${TARGET}') does not support the flag '$3'"
      ;;
    *)     die 1 "DEV: handle() - command '$2' mistyped" ;;
  esac
}

flag() {
  case "$1" in
    SINGLE)       handle 'SINGLE'       "$2" '-1' '--single            ' "$3" ;;
    SYNC)         handle 'SYNC'         "$2" '-e' '--external          ' "$3" ;;
    FORCE)        handle 'FORCE'        "$2" '-f' '--force             ' "$3" ;;
    HELP)         handle 'HELP'         "$2" '-h' '--help              ' "$3" ;;
    INFO)         handle 'INFO'         "$2" '-i' '--info              ' "$3" ;;
    MANUAL)       handle 'MANUAL'       "$2" '-m' '--manual            ' "$3" ;;
    ORPHANS)      handle 'ORPHANS'      "$2" '-o' '--orphans           ' "$3" ;;
    PRINT)        handle 'PRINT'        "$2" '-p' '--print             ' "$3" ;;
    QUIET)        handle 'QUIET'        "$2" '-q' '--quiet             ' "$3" ;;
    SOURCE)       handle 'SOURCE'       "$2" '-s' '--source            ' "$3" ;;

    DEPENDENTS)   handle 'DEPENDETS'    "$2" '-d' '--dependents        ' "$3" ;;
    PROVIDESFOR)  handle 'PROVIDESFOR'  "$2" '-r' '--reverse-dependents' "$3" ;;
    all)
      shift 1
      for arg in SINGLE SYNC FORCE HELP INFO MANUAL ORPHANS PRINT SOURCE \
          QUIET DEPENDENTS PROVIDESFOR; do
        flag "${arg}" "$@"
      done
      ;;
    *)  die 1 "DEV: flag() - flag name '$1' mistyped" ;;
  esac
}

# This will be used in two situations
# First to check user input
# Second to check if
match_manager() {
  case "$1" in
    pip|python)      match_any "${TARGET}" "python" "pip" ;;
    cargo|rust)      match_any "${TARGET}" "rust" "cargo" ;;
    apt|dpkg|debian)
      [ -z "${TARGET}" ] || match_any "${TARGET}" "apt" "dpkg" "debian" ;;
    pacman|arch|archlinux)
      [ -z "${TARGET}" ] || match_any "${TARGET}" "pacman" "arch" "archlinux" ;;
    xbps|void|voidlinux)
      [ -z "${TARGET}" ] || match_any "${TARGET}" "xbps" "void" "voidlinux" ;;
    ?*)  die 1 "FATAL: '$1' is not a valid package manager" ;;
    *)   true ;;
  esac
}



###############################################################################
# Branches
help_install() {
  name="$(basename "$0"; printf a)"; name="${name%??}"
  <<EOF cat - >&2
USAGE: ${name} -I  [OPTIONS]
  -s


EOF
}

# Note on using force to install a specific version of a package
package_install() {
  if flag HELP GET; then
    help_install; exit 0
  fi
  if match_manager void && require xbps-install; then
    cmd="$(if flag SOURCE GET
      then prints xbps-source
      else prints xbps-install
    fi)"
    options="$(
      flag SYNC GET && prints "S"
      flag FORCE GET && prints "f"
      flag MANUAL GET && prints "u"
    )"
    if [ -n "${options}" ]
      then _print "${_SUDO}" "${cmd}" "-${options}" "$@"
      else _print "${_SUDO}" "${cmd}" "$@"
    fi
  fi

  if match_manager arch && require pacman; then
    options="$(
      flag SYNC GET && prints "S"
      prints "y"
      #flag FORCE GET && prints "y"
      flag MANUAL GET && prints "u"
    )"
    if [ -n "${options}" ]
      then _print "${_SUDO}" pacman "-${options}" "$@"
      else _print "${_SUDO}" pacman "$@"
    fi
  fi

  # Forgot how apt-get works, so skipping for now
  if match_manager debian && { require apt || require apt-get; }; then
    flag SYNC GET && _print "${_SUDO}" apt update
    flag MANUAL GET && _print "${_SUDO}" apt upgrade
    #flag FORCE GET && _print "${_SUDO}"
  fi
}

# Flags to check checklist:
# SINGLE
# MANUAL
# ORPHANS
# INFO
# DEPENDENTS
# PROVIDESFOR
# SYNC
package_query() {
  if match_manager void && require xbps-query; then
    post_process="$(
      if  ! flag MANUAL GET && ! flag ORPHANS GET && {
        flag INFO GET || flag DEPENDENTS GET || flag PROVIDESFOR GET
      }
      then prints "${ENUM_TRUE}"
      else prints "${ENUM_FALSE}"
    fi)"

    # TODO: ditch _pbar? does not seem to be a way to guarentee order
    #       `sed 1q`, `uniq`, `sort` all seem to print first

    { { if flag ORPHANS GET; then   _print xbps-query -O
        #elif flag LOCKS GET; then
        elif flag MANUAL GET; then  _print xbps-query -m

        # The following (because -s) need a second field cut (cut after grep)
        elif flag SYNC GET; then    _print xbps-query -Rs ' '
        else                        _print xbps-query -s ' '
        fi

        # NOTE: Want the splitting for grep
      } | { [ "$#" -gt 0 ]; do_if "$?" _pbar grep -i $(printf -- " -e %s" "$@")
      } | { flag SINGLE GET; <&0 do_if "$?" _pbar sed 1q
      } | do_if "${post_process}" _pbar cut -d " " -f 2 \
      | { [ "${post_process}" = "${ENUM_TRUE}" ] && ! flag QUIET GET
        do_if "$?" _pbar xargs sh -c '
          printf %s\\n >&2 -- \
            "Quering the following packages (-q to silence):" \
            "\"-q to silence\"" "\"-1 to limit to dependency search\"" ""
          printf "%s " "$@" >&2
          printf \\n====\\n >&2
          printf %s\\n "$@"
        ' _;
      } | {
        if flag DEPENDENTS GET; then
          flag SYNC GET && puterr \
            "ERROR: xbps cannot query dependencies of external programs." \
            "Skipping all non-installed programs..." \
            "===="

          # NOTE: `_pbar sort` and `_pbar uniq` execute first for some reason
          #       before the other PRINT flag prints occur
          _pbar xargs -n 1 xbps-query -x | sort | uniq
          #_pbar xargs -n 1 xbps-query -x | _pbar sort | _pbar uniq
        elif flag PROVIDESFOR GET; then
          flag SYNC GET && puterr \
            "ERROR: xbps cannot query the reverse dependencies"  \
            "of external programs." \
            "Skipping all non-installed programs..." \
            "===="
          _pbar xargs -n 1 xbps-query -X | sort | uniq
        elif flag INFO GET; then
          _pbar xargs -n 1 -I {} sh -c "xbps-query -S {}; echo '===='"
        else
          cat -
        fi
      }
    }
  fi

  if match_manager rust && require cargo; then
    flag MANUAL GET        && flag MANUAL      UNSUPPORTED
    flag SINGLE GET        && flag SINGLE      UNSUPPORTED
    flag ORPHANS GET       && flag ORPHANS     UNSUPPORTED
    flag INFO GET          && flag INFO        UNSUPPORTED
    flag DEPENDENTS GET    && flag DEPENDENTS  UNSUPPORTED
    flag PROVIDESFOR GET   && flag PROVIDESFOR UNSUPPORTED


    { { if flag SYNC GET; then  cargo search "$@"
        else                    cargo install --list
        fi
      } | { flag SINGLE GET; do_if "$?" sed 1q;
      }
    }
  fi
}

# Use ${ORPHANS} for autoremove? or use for cleanup method?
package_remove() {
  if match_manager void && require xbps-remove; then
    options="$(
      flag SINGLE GET || prints "R"
      flag FORCE GET && prints "f"
      flag ORPHANS GET && prints "o"
    )"
    if [ -n "${options}" ]
      then _print "${_SUDO}" xbps-remove "-${options}" "$@"
      else _print "${_SUDO}" xbps-remove "$@"
    fi
  fi

  if match_manager python && require pip; then
    die 1 'WIP'
    #options="$(
    #  flag SINGLE GET || prints "r"
    #)"
    #if [ -n "${options}" ]
    #  then _print "${_SUDO}" pip uninstall "-${options}" "$@"
    #  else _print "${_SUDO}" pip uninstall "$@"
    #fi
  fi
}


# Helpers
puts() { printf %s\\n "$@"; }
puterr() { printf %s\\n "$@" >&2; }
prints() { printf %s "$@"; }
die() { exitcode="$1"; shift 1; printf %s\\n "$@" >&2; exit "${exitcode}"; }
require() { command -v "$1" >/dev/null 2>&1; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

match_any() {
  matchee="$1"; shift 1
  [ -z "${matchee}" ] && return 1
  for matcher in "$@"; do
    case "${matchee}" in "${matcher}") return 0 ;; esac
  done
  return 1
}

# NOTE: Using awk instead of prints because could not output
#       may be due to shell commands running in parallel to forked processes
#       but honestly have no idea. Thus not really sure if using awk
#       actually guarentees the order or not.
_print() {
  if flag PRINT GET; then
    cmd="$(for a in "$@"; do prints "$(puts "$a" | eval_escape) "; done)"
    </dev/null awk "END{ print \"${cmd% } \\\\\"; }" >&2
    #prints "${cmd% }" >&2  # Using awk instead to guarentee? order
    #puts  # Add newline (not to STDERR though)
  else
    "$@"
  fi
}

# See _print() for why we are using awk instead of prints
_pbar() {
  if flag PRINT GET; then
    cmd="$(for a in "$@"; do prints "$(puts "$a" | eval_escape) "; done)"
    awk "END{ print \" | ${cmd% } \\\\\"; }" >&2
    #prints " | ${cmd% }" >&2  # Using awk instead to guarentee? order
    #cat -   # Add newline from _print() (not to STDERR though)
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
