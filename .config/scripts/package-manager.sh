#!/usr/bin/env sh

name="$( basename "$0"; printf a )"; name="${name%?a}"

show_help() {
  padding="$( flag_all BOTH | awk '
    (1) { l = (l > length($0)) ? l : length($0); }
    END { print l; }
  ' )"
  <<EOF cat - >&2
SYNOPSIS
  ${name} [OPTIONS] [PKG1 [PKG2 [...]]]

DESCRIPTION

OPTIONS
  -x,--target PACKAGE_MANAGER   Specify a package manager

  -E,--edit                 Edit
  -C,--reconfigure          WIP
  -I,--install              Install packages
  -Q,--query                Exit
  -R,--remove               Exit

  $(flag SYNC BOTH "${padding}"        )  Sync local and external repository
  $(flag FORCE BOTH "${padding}"       )  WIP, force version numbers?
  $(flag HELP BOTH "${padding}"        )  Display help
  $(flag QUIET BOTH "${padding}"       )  Mutes some explaination text
  $(flag SOURCE BOTH "${padding}"      )  Use source compiler

  $(flag SINGLE BOTH "${padding}"      )  Limit to just one or no dependencies
  $(flag MANUAL BOTH "${padding}"      )  Stuff
  $(flag ORPHANS BOTH "${padding}"     )  Stuff

  $(flag DEPENDENTS BOTH "${padding}"  )  Stuff
  $(flag INFO BOTH "${padding}"        )  Stuff
  $(flag PRINT BOTH "${padding}"       )  Stuff
  $(flag PROVIDESFOR BOTH "${padding}" )  Stuff
EOF
}

ENUM_TRUE=0
#ENUM_FALSE=1

ENUM_EDIT=1
ENUM_INSTALL=2
ENUM_QUERY=3
ENUM_REMOVE=4
ENUM_RECONFIG=5

# Handles single character-options joining (eg. pacman -Syu)
main() {
  # Flags
  TARGET=''
  COMMAND=''
  flag_all SET 'false'

  # Dependencies

  # Options processing
  args=''
  literal='false'
  while [ "$#" -gt 0 ]; do
    if ! "${literal}"; then
      # Split grouped single-character arguments up, and interpret '--'
      # Parsing '--' here allows "invalid option -- '-'" error later
      opts=''
      case "$1" in
        --)      literal='true'; shift 1; continue ;;
        -[!-]*)  opts="${opts}$( soutln "${1#-}" | sed 's/./ -&/g' )" ;;
        *)       opts="${opts} $1" ;;
      esac

      # Process arguments properly now
      for x in ${opts}; do case "${x}" in
        -h|--help)  show_help; exit 0 ;;
        -x|--target)  TARGET="$2"; shift 1 ;;

        -E|--edit)         COMMAND="${ENUM_EDIT}" ;;
        -D|--debug)        COMMAND="${ENUM_RECONFIG}" ;;
        -I|--install)      COMMAND="${ENUM_INSTALL}" ;;
        -Q|--query)        COMMAND="${ENUM_QUERY}" ;;
        -R|--remove)       COMMAND="${ENUM_REMOVE}" ;;
 
        "$(flag SYNC MIN)"|"$(flag SYNC MAX)")        flag SYNC SET 'true' ;;
        "$(flag FORCE MIN)"|"$(flag FORCE MAX)")      flag FORCE SET 'true' ;;
        "$(flag HELP MIN)"|"$(flag HELP MAX)")        flag HELP SET 'true' ;;
        "$(flag QUIET MIN)"|"$(flag QUIET MAX)")      flag QUIET SET 'true' ;;
        "$(flag SOURCE MIN)"|"$(flag SOURCE MAX)")    flag SOURCE SET 'true' ;;

        "$(flag SINGLE MIN)"|"$(flag SINGLE MAX)")    flag SINGLE SET 'true' ;;
        "$(flag MANUAL MIN)"|"$(flag MANUAL MAX)")    flag MANUAL SET 'true' ;;
        "$(flag ORPHANS MIN)"|"$(flag ORPHANS MAX)")  flag ORPHANS SET 'true' ;;

        "$(flag INFO MIN)"|"$(flag INFO MAX)")        flag INFO SET 'true' ;;
        "$(flag PRINT MIN)"|"$(flag PRINT MAX)")      flag PRINT SET 'true' ;;
        "$(flag DEPENDENTS MIN)"|"$(flag DEPENDENTS MAX)")
          flag DEPENDENTS SET 'true' ;;
        "$(flag PROVIDESFOR MIN)"|"$(flag PROVIDESFOR MAX)")
          flag PROVIDESFOR SET 'true' ;;


        # Put argument checks above this line (for error detection)
        # first '--' case already covered by first case statement
        -[!-]*)   show_help; die 1 'FATAL' "invalid option '${x#-}'" ;;
        *)        args="${args} $( soutln "$1" | eval_escape )" ;;
      esac done
    else
      args="${args} $( soutln "$1" | eval_escape )"
    fi
    shift 1
  done

  match_manager "${TARGET}"  # Validate manager or `die`

  #[ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"

  case "${COMMAND}" in
    "${ENUM_EDIT}")      edit_void "$@" ;;
    "${ENUM_INSTALL}")   package_install "$@" ;;
    "${ENUM_QUERY}")     query_void "$@" ;;
    "${ENUM_REMOVE}")    package_remove "$@" ;;
    "${ENUM_RECONFIG}")  echo WIP ;;
    *)  show_help; if flag HELP CHECK; then exit 0; else exit 1; fi ;;
  esac
  err="$?"
  flag PRINT CHECK && soutln
  return "${err}"
}

################################################################################
# Flag stuff
ALL_FLAGS=''
FLAG_SETUP='true'
_e() {
  "${FLAG_SETUP}" && ALL_FLAGS="${ALL_FLAGS} $2"
  [ "$1" = "$2" ] && soutln "$3,$4,$5"
}
data() {
  _e "$1" "SINGLE"      -1 --single             "${FLAG_SINGLE}"
  _e "$1" "SYNC"        -e --external           "${FLAG_SYNC}"
  _e "$1" "FORCE"       -f --force              "${FLAG_FORCE}"
  _e "$1" "HELP"        -h --help               "${FLAG_HELP}"
  _e "$1" "INFO"        -i --info               "${FLAG_INFO}"
  _e "$1" "MANUAL"      -m --manual             "${FLAG_MANUAL}"
  _e "$1" "ORPHANS"     -o --orphans            "${FLAG_ORPHANS}"
  _e "$1" "PRINT"       -p --print              "${FLAG_PRINT}"
  _e "$1" "QUIET"       -q --quiet              "${FLAG_QUIET}"
  _e "$1" "SOURCE"      -s --source             "${FLAG_SOURCE}"
  _e "$1" "DEPENDENTS"  -d --dependents         "${FLAG_DEPENDENTS}"
  _e "$1" "PROVIDESFOR" -r --reverse-dependents "${FLAG_PROVIDESFOR}"
  FLAG_SETUP='false'
}
flag_all() {
  data  # sets ${ALL_FLAGS}
  for arg in ${ALL_FLAGS}; do flag "${arg}" "$@"; done
}
flag() {
  read_from "$( data "$1" )" ',' f_short f_long f_data
  case "$2" in
    MIN)          sout "${f_short}" ;;
    MAX)          sout "${f_long}" ;;
    BOTH)         printf "%-$3s"\\n "${f_short}, ${f_long}" ;;
    SET)          eval "FLAG_$1"=\"$3\" ;;
    CHECK)        "${f_data}" ;;
    UNSUPPORTED)  die 1 'FATAL' "'${TARGET}' does not support '${f_long}'" ;;
    *)            die 2 'DEV' "\`flag\` command '$2' was mistyped"
  esac
}



################################################################################
# Edit the configs
edit_void() {
  _sudo cp -i /usr/share/xbps.d/00-repository-main.conf /etc/xbps.d/
  _new_cmd
  _sudo "${EDITOR:-vim}" '/etc/xbps.d/00-repository-main.conf'
}



################################################################################
# Install
package_install() {
  {  _specified_or_exists 'xbps' 'xbps-install' install_xbps "$@" \
  || _specified_or_exists 'apt' 'apt' install_apt "$@" \
  || die 1 'WIP' 'Installer not implemented' \
  ; }
}


install_xbps() {
  cmd="$( if flag SOURCE CHECK
    then sout 'xbps-source'  # TODO: actually check if this works
    else sout 'xbps-install'
  fi )"
  options="$(
    flag SYNC CHECK &&   sout 'S'
    flag FORCE CHECK &&  sout 'f'
    flag MANUAL CHECK && sout 'u'
  )"
  if [ -z "${options}" ]  # Attempts to install '' so have to branch here
    then _sudo "${cmd}" "$@"
    else _sudo "${cmd}" "-${options}" "$@"
  fi
}

install_apt() {
  cmd="$( if flag SOURCE CHECK
    then sout 'apt-get'  # TODO: actually check if this works
    else sout 'apt'
  fi )"
  flag SYNC CHECK && {   _sudo "${cmd}" update;  _new_cmd; }
  flag MANUAL CHECK && { _sudo "${cmd}" upgrade; _new_cmd; }
  [ "$#" -gt 0 ] && _sudo "${cmd}" "$@"
}



################################################################################
# Query
query_void() {
  require 'xbps-query' || die 1 'FATAL' '`xbps-query` not installed'

  count=0
  flag MANUAL CHECK && count="$(( count + 1 ))"
  flag SYNC CHECK && count="$(( count + 1 ))"
  flag ORPHANS CHECK && count="$(( count + 1 ))"
  [ "${count}" -ge 2 ] && die 1 'FATAL' "Cannot have any two of $(
    flag MANUAL MAX ), $( flag SYNC MAX ), or $( flag ORPHANS MAX
    ) set at the same time."

  query="$( {
    if flag ORPHANS CHECK; then   _do xbps-query -O
    #elif flag LOCKS CHECK; then
    elif flag MANUAL CHECK; then  _do xbps-query -m  # Manually installed

    # The following (because -s) need a second field cut (cut after grep)
    elif flag SYNC CHECK; then    _do xbps-query -Rs \*
    else                          _do xbps-query -s \*
    fi
  } | {
    [ "$#" -gt 0 ]; _bar_if "$?" grep -i $( printf " -e %s" "$@" )
  } )"

  # Not piping directly to the following to deal with the timing issues
  # (`_bar sort` and `_bar uniq` occuring before print flag? (old notes))
  if flag INFO CHECK || flag DEPENDENTS CHECK || flag PROVIDESFOR CHECK
  then
    flag SYNC CHECK && serrln \
      "WARNING: Cannot query info '$( flag INFO MIN )' , dependents $(
      flag DEPENDENTS MIN ), or reverse dependents $( flag PROVIDESFOR MIN
      ) of repository-only packages (enabled from $( flag SYNC MIN ) )." \
      "Skipping all non-install packages" \
      "===="

    sout "${query}" \
    | _bar cut -d ' ' -f 2 \
    | _verbose_display \
    | {
      if flag DEPENDENTS CHECK; then
        _bar xargs -n 1 xbps-query -x | _bar sort | _bar uniq
      elif flag PROVIDESFOR CHECK; then

        _bar xargs -n 1 xbps-query -X | _bar sort | _bar uniq
      elif flag INFO CHECK; then
        _bar xargs -n 1 -I {} sh -c "xbps-query -S {}; echo '===='"
      fi
    }
  else soutln "${query}"
  fi
}


################################################################################
# Remove, recursive by default
package_remove() {
  {  _specified_or_exists 'xbps' 'xbps-remove' remove_xbps "$@" \
  || _specified_or_exists 'apt' 'apt' remove_apt "$@" \
  || die 1 'WIP' 'Installer not implemented'
  }
}

remove_apt() {
  apt remove "$@"
}

remove_xbps() {
  require 'xbps-remove' || die 1 'FATAL' '`xbps-remove` not installed'
  options="$(
    flag SINGLE  CHECK || sout "R"
    flag FORCE   CHECK && sout "f"
    flag ORPHANS CHECK && sout "o"
  )"
  if [ -n "${options}" ]  # Attempts to install '' so have to branch here
    then _sudo xbps-remove "-${options}" "$@"
    else _sudo xbps-remove "$@"
  fi
}

################################################################################
# Package manager helpers
_match_any_and_print() {
  matchee="$1"; shift 1
  for arg in "$@"; do
    case "${arg}" in "${matchee}")  printf ' %s' "$@"; return 0 ;; esac
  done
  return 1
}
# Runs
match_manager() {
  matching_set="$(
    [ -z "$1" ] \
    || _match_any_and_print "$1" xbps void voidlinux \
    || _match_any_and_print "$1" apt debian ubuntu apt-get \
    || _match_any_and_print "$1" pacman arch archlinux \
    || _match_any_and_print "$1" cargo rust \
    || _match_any_and_print "$1" pip pip3 python \
    || exit 1
  )" || die 1 'FATAL' "'$1' is not a valid package manager"
  eval "set -- ${matching_set}"
  [ -z "${TARGET}" ] || _match_any_and_print "${TARGET}" "$@" >/dev/null \
    || die 1 'FATAL' "'${TARGET}' is not a valid package manager"
}

_specified_or_exists() {
  if match_manager "$1" && require "$2"
    then shift 2; "$@"; return 0
    else return 1
  fi
}

# Add a header to the output
_verbose_display() {
  ! flag QUIET CHECK
  <&0 _do_if "$?" _bar xargs sh -c '
    printf %s\\n >&2 -- \
      "Quering the following packages (-q to silence):" \
      "\"-q to silence\"" "\"-1 to limit to dependency search\"" ""
    printf "%s " "$@" >&2
    printf \\n====\\n >&2
    printf %s\\n "$@"
  ' _
}


################################################################################
# Various IO commands

# Do not pipe to this to retain namespace
read_from() {
  first="$1"; shift 1
  separator="$1"; shift 1
  # Cannot pipe here either because of namespaces
  IFS="${separator}" read -r "$@" <<EOF
${first}
EOF
}


_do() {
  if flag PRINT CHECK; then
    cmd="$( for a in "$@"; do sout "$( sout "$a" | eval_escape ) "; done )"
    sout "${cmd% }"
  else
    "$@"
  fi
}

_sudo() {
  if c.sh is-android
    then _do "$@"
    else _do sudo "$@"
  fi
}

_do_if() {
  if [ "$1" = "${ENUM_TRUE}" ]
    then shift 1; _do "$@"
    else <&0 cat -
  fi
}

_bar() {
  if flag PRINT CHECK; then
    cmd="$( for a in "$@"; do sout "$( sout "$a" | eval_escape ) "; done )"
    # sleep 0.05  # Running into timing issues cause things to go out of order
    cat -; sout " | ${cmd% }"
  else
    "$@"
  fi
}
_bar_if() {
  if [ "$1" = "${ENUM_TRUE}" ]
    then shift 1; _bar "$@"
    else <&0 cat -
  fi
}

_new_cmd() { flag PRINT CHECK && sout '; '; }

sout() { printf %s "$@"; }
soutln() { printf %s\\n "$@"; }
serrln() { printf %s\\n "$@" >&2; }
die() { c="$1"; serrln "$2: '${name}' -- $3"; shift 3; serrln "$@"; exit "$c"; }
require() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0
  done
  return 1
}
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
