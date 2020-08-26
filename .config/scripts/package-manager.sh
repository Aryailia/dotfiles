#!/usr/bin/env sh

name="$( basename "$0"; printf a )"; name="${name%?a}"

show_help() {
  pad="$( outln "${DATA}" | awk -v FS=',' '
    { if (l < length($3) + length($4)) l = length($3) + length($4); }
    END{ print(l + 2); }  # Comma and space
  ')"
  #outln "${DATA}" | cut -d, -f 4
  #exit
  <<EOF cat - >&2
SYNOPSIS
  ${name} - [<CSV_FILE1> ...]
  ${name} <CSV_FILE1> [<CSV_FILE2> ...]
  ${name} -G <BUILD_DIR> <url1> [<url2 ...]
  ${name} <ACTION> [<FLAGS>] [<PACKAGE1> ...]

DESCRIPTION
  For dealing with the various package managers across platforms because it is
  difficult to remember all the options.  You can specify the print flag to
  show the commands being executed.

  Hyphen-option in short form can be combined with other hyphen-options.
  The query for dependants by default may be annoying.  But consistency.

ACTIONS (only use one)
  $( printf "%-${pad}s" None    )  Process via csv
  $( get config  padSL "${pad}" )  For editing packager/package configs
  $( get install padSL "${pad}" )  For package installation
  $( get query   padSL "${pad}" )  For searching for package
  $( get remove  padSL "${pad}" )  For package removal
  $( get git     padSL "${pad}" )  Git install, update if project already exists

REPOSITORY TARGET (default to external + local)
  $( get EXTERN  padSL "${pad}" )  Limit to just external
  $( get LOCAL   padSL "${pad}" )  Limit to just local
  $( get SOURCE  padSL "${pad}" )  If supports building from source, do so
  $( get SYNC    padSL "${pad}" )  Update the local repository
  $( get CACHE   padSL "${pad}" )  WIP (Operate on the cache)

PACKAGE MODIFIERS (default to include dependents)
  $( get SINGLE  padSL "${pad}" )  No dependants/derivates (query default)
  $( get ORPHANS padSL "${pad}" )  No dependants/derivates, not manual
  $( get PROVIDE padSL "${pad}" )  Software that depends on the search
  $( get YES     padSL "${pad}" )  When used with query, manual installs

MISCELLANEOUS
  $( get FORCE   padSL "${pad}" )  WIP (Force flag)
  $( get INFO    padSL "${pad}" )  Show descriptions
  $( get PRINT   padSL "${pad}" )  Print out the commands instead of running
  $( get QUIET   padSL "${pad}" )  WIP (Silence output)
  $( get YES     padSL "${pad}" )  Auto yes

  -
    Read from STDIN

  --
    Special argument that prevents all following arguments from being
    intepreted as options.

  -x <>

EXAMPLES
  ${name} -Iuly              | Update package list, install updates, auto yes
  ${name} -Il                | Install any known updates
  ${name} -I dmenu st dwm    | Install some packages
  ${name} programs.csv a.csv | Process these csv files
  ${name} -                  | Interpret STDIN as a csv
  ${name} -I -- -R           | Install a package with a difficult name
  ${name} -Q1u emacs         | Update package list, then search
  ${name} -Q1 firefox sxhkd  | Search the external/internal repo
  ${name} -Q sxiv            | Search the external/internal repo for depedents
  ${name} -Ql ati            | Search just for locally installed
  ${name} -Qe tmux           | TODO (Search non-installed)
  ${name} -Qy                | Find manually installed software
  ${name} -Qo                | Find orphans
  ${name} -Ii wayland        | find installed files info
  ${name} -R xorg            | Remove package and its dependents
  ${name} -R1 i3-status      | Remove just the specified package
  ${name} -Ro                | Remove orphans
  ${name} -Rc                | TODO (Clear the cache)

EOF
}

NL='
'

DATA="ErRoR,
,$( printf '%s,' \
  config  -C --Config      1     "${NL}" \
  install -I --Install     2     "${NL}" \
  query   -Q --Query       3     "${NL}" \
  remove  -R --Remove      4     "${NL}" \
  git     -g --Git         5     "${NL}" \
  CACHE   -c --cache       false "${NL}" \
  EXTERN  -e --external    false "${NL}" \
  LOCAL   -l --local       false "${NL}" \
  SOURCE  -s --source      false "${NL}" \
  SYNC    -u --update      false "${NL}" \
  SINGLE  -1 --single      false "${NL}" \
  PROVIDE -r --derivatives false "${NL}" \
  ORPHANS -o --orphans     false "${NL}" \
  INFO    -i --info        false "${NL}" \
  FORCE   -f --force       false "${NL}" \
  PRINT   -p --print       false "${NL}" \
  QUIET   -q --quiet       false "${NL}" \
  YES     -y --yes         false "${NL}" \
)"

PACKAGE_MANAGER_ALIASES=",$( printf "%s," \
  xbps    xbps void    "${NL}" \
  apt     apt          "${NL}" \
  pacman  pacman arch  "${NL}" \
  node    node nodejs  "${NL}" \
  cargo   cargo rust   "${NL}" \
  pip     pip python   "${NL}" \
  #pkg   pkg bsd     "${NL}" \
)"

################################################################################
# Main
main() {
  process_options "$@"
  eval "set -- ${ARGS}"

  case "${CMD}" in
    "$( get config  v )")  process_action "${PACKAGEMANAGER}" config  "$@" ;;
    "$( get install v )")  process_action "${PACKAGEMANAGER}" install "$@" ;;
    "$( get query   v )")  process_action "${PACKAGEMANAGER}" query   "$@" ;;
    "$( get remove  v )")  process_action "${PACKAGEMANAGER}" remove  "$@" ;;
    "")
      "${STDIN}" && { outln "----" "Processing STDIN"; <&0 process_csv; }
      for x in "$@"; do
        outln "---- Processing '${x}'"
        <"${x}" process_csv
      done
      ;;
    *)   die 2 DEV "Mispelt a \${CMD}: Hello"
  esac
}


# NOTE: cannot pipe to `main` or it will eat the [y/n] prompt
# Type,a,b,c
process_csv() {
 #</dev/tty main ${args} \
  while IFS=, read -r args description; do
  [ -n "${args}" ] && </dev/tty main ${args} \
      || die 1 FATAL "Error at with line: ${args},${description}"
  done
  [ -n "${args}" ] && </dev/tty main ${args} \
    || die 1 FATAL "Error at with line: ${args},${description}"
  #input="${1}"
  #while [ -n "${input}" ];  do
  #  line="${input%%${NL}*}"
  #  input="${input#"${line}"}"
  #  input="${input#${NL}}"
  #  line="${line%%,*}"
  #  [ -n "${line}" ] && </dev/tty main ${line}
  #done
}


# Handles single character-options joining (eg. pacman -Syu)
process_options() {
  STDIN='false'
  CMD=''
  PACKAGEMANAGER=''

  ARGS=''
  literal='false'
  while [ "$#" -gt 0 ]; do
    if ! "${literal}"; then
      # Split grouped single-character arguments up, and interpret '--'
      # Parsing '--' here allows "invalid option -- '-'" error later
      case "$1" in
        --)      literal='true'; shift 1; continue ;;
        -)       STDIN='true'; shift 1; continue ;;
        -[!-]*)  opts="$( outln "${1#-}" | sed 's/./ -&/g' )" ;;
        --?*)    opts="$1" ;;
        *)       opts="regular" ;;  # Any non-hyphen value will do
      esac

      # Process arguments properly now
      for x in ${opts}; do case "$x" in
        -h|--help)  show_help; exit 0 ;;
        -x|--executable)  PACKAGEMANAGER="${2}"; shift 1 ;;

        "$( get config  S )"|"$( get config  L )")  CMD="$( get config  v )" ;;
        "$( get install S )"|"$( get install L )")  CMD="$( get install v )" ;;
        "$( get query   S )"|"$( get query   L )")  CMD="$( get query   v )" ;;
        "$( get remove  S )"|"$( get remove  L )")  CMD="$( get remove  v )" ;;
        "$( get git     S )"|"$( get git     L )")  CMD="$( get git     v )" ;;

        "$( get CACHE   S )"|"$( get CACHE   L )")  put CACHE   true ;;
        "$( get LOCAL   S )"|"$( get LOCAL   L )")  put LOCAL   true ;;
        "$( get EXTERN  S )"|"$( get EXTERN  L )")  put EXTERN  true ;;
        "$( get SOURCE  S )"|"$( get SOURCE  L )")  put SOURCE  true ;;
        "$( get SYNC    S )"|"$( get SYNC    L )")  put SYNC    true ;;

        "$( get SINGLE  S )"|"$( get SINGLE  L )")  put SINGLE  true ;;
        "$( get ORPHANS S )"|"$( get ORPHANS L )")  put ORPHANS true ;;
        "$( get PROVIDE S )"|"$( get PROVIDE L )")  put PROVIDE true ;;

        "$( get FORCE   S )"|"$( get FORCE   L )")  put FORCE   true ;;
        "$( get INFO    S )"|"$( get INFO    L )")  put INFO    true ;;
        "$( get PRINT   S )"|"$( get PRINT   L )")  put PRINT   true ;;
        "$( get QUIET   S )"|"$( get QUIET   L )")  put QUIET   true ;;
        "$( get YES     S )"|"$( get YES     L )")  put YES     true ;;


        # Put argument checks above this line (for error detection)
        # first '--' case already covered by first case statement
        -[!-]*)   show_help; die 1 FATAL "invalid option '${x#-}'" ;;
        *)        ARGS="${ARGS} $( outln "$1" | eval_escape )" ;;
      esac done
    else
      ARGS="${ARGS} $( outln "$1" | eval_escape )"
    fi
    shift 1
  done
}

process_action() {
  _pm="${1}"     # specified package manager
  _action="${2}" # program action
  shift 2
  # $...: the packages to install
  if [ -z "${_pm}" ]; then  # Automatically detect if blank
    if   xbps_test    "${_action}"; then "xbps_${_action}"    "$@"
    elif apt_test     "${_action}"; then "apt_${_action}"     "$@"
    elif pacman_test  "${_action}"; then "pacman_${_action}"  "$@"
    #elif rust_test    "${2}"; then "rust_${2}"    "$@"
    else die 1 FATAL 'Default package manager not found, try -x option'
    fi
  else  # ${_pm} specifies a package manager to use
    # match "${_pm}"
    _tool="$( outln "${PACKAGE_MANAGER_ALIASES}" \
      | grep -F ",${_pm}," \
      | cut -d ',' -f 2 \
    )"
    if [ -n "${_tool}" ]; then
      "${_tool}_${_action}" "$@"
    else
      die 1 FATAL "'${_pm}' is not currently supported"
    fi
  fi
}

git_install() {
  cd "${1}" || die 1 FATAL "Build directory '${1}' does not exist"
  shift 1
  for _x in "$@"; do
    _x="${_x##*/}"; _x="${_x%.*}"
    if [ -d  "${_x}" ]; then
      _do git --git-dir="${_x}" fetch
      _do git --git-dir="${_x}" pull
    else
      _do git clone "${1}"
    fi
    _do make
    _sudo make install
  done
}

################################################################################
# Void Linux's XBPS
xbps_test() {
  # $1: the program action
  case "${1}" in
    config)  require "xbps-install" ;;
    *)       require "xbps-${1}" ;;
  esac
}

xbps_config() {
  if [ "$#" = 0 ]; then
    if get SYNC t; then
      _sudo "${EDITOR}" '/etc/xbps.d/00-repository-main.conf'
    elif get LOCAL t; then
      _do xbps-query -L
    elif get INFO t; then
      outln "---- '/usr/share/xbps.d/' -----"
      ls '/usr/share/xbps.d/'

      outln "" "--- /etc/xbps.d ---"
      ls '/etc/xbps.d/'
    else
      outln "Try:" \
        "  $( get SYNC  padSL )" \
        "  $( get LOCAL padSL )" \
        "  $( get INFO  padSL )" \
        ""
    fi
  else
    outln "reconfig a package - WIP"
  fi
}

xbps_install() {
  get SOURCE t && die 1 FATAL "Option $( get SOURCE padSL ) is unsupported"
  __cmd="$( if get SOURCE t
    then out 'xbps-source'
    else out 'xbps-install'
  fi )"
  __options="$(
    get SYNC t   && out 'S'
    get FORCE t  && out 'f'
    get LOCAL t  && out 'u'
    get YES t    && out 'y'
  )"
  if get INFO t; then
    require 'xbps-query' || die 1 FATAL "\`xbps-query\` not found"
    for x in "$@"; do _do xbps-query -Rf "${x}"; done
  else
    if [ -z "${__options}" ]
      then _sudo "${__cmd}" "$@"
      else _sudo "${__cmd}" "-${__options}" "$@"
    fi
  fi
}

xbps_query() {
  if get SYNC t; then
    require 'xbps-install' || die 1 FATAL "\`xbps-install\` is not installed"
    _sudo xbps-install -S
  fi
  require 'xbps-query' || die 1 FATAL "\`xbps-query\` is not installed"

  __options="$(
    get INFO t || get LOCAL t || out 'R'
    x=0
    get ORPHANS t && { out 'O'; x="$(( x + 1 ))"
      get LOCAL t || errln "$( get ORPHANS S ) implies $( get LOCAL S )" ""
    }
    get YES t     && { out 'm'; x="$(( x + 1 ))"; }  # Manual installs
    [ "${x}" -gt 2 ] && die 1 FATAL "conflicting options"

    x=0
    get SINGLE t  || { out 'x'; x="$(( x + 1 ))"; }
    get PROVIDE t && { out 'X'; x="$(( x + 1 ))"; }
    get INFO t    && { out 'i'; x="$(( x + 1 ))"; }  # Does not like -R
    [ "${x}" = 0 ] &&      out 's'
    [ "${x}" -gt 2 ] && die 1 FATAL "conflicting options"
    true
  )" || exit "$?"

  if [ "$#" = 0 ]
    then _do xbps-query "-${__options}" '*'
    else for x in "$@"; do _do xbps-query "-${__options}" "${x}"; done
  fi
}

xbps_remove() {
  require 'xbps-remove' || die 1 FATAL "\`xbps-remove\" is not installed"
  __options="$(
    get SINGLE t  || out 'R'
    get FORCE t   && out 'f'
    get ORPHANS t && out 'o'
    get YES t     && out 'y'
  )"
  _sudo xbps-remove "-${__options}" "$@"
}


################################################################################
#
apt_test() { require apt; }
apt_install() {
  get SOURCE t && die 1 FATAL "Option $( get SOURCE padSL ) is unsupported"
  get INFO t   && die 1 FATAL "Option $( get INFO   padSL ) is unsupported"
  get YES t    && die 1 FATAL "Option $( get YES    padSL ) is unsupported"

  __cmd="apt$( get SOURCE t && out '-get' )"
  get SYNC  t && _do "${__cmd}" update
  get LOCAL t && _do "${__cmd}" upgrade
  [ "$#" -gt 0 ] && _do "${__cmd}" install "$@"
}

################################################################################
# Arch Linux's `pacman`
pacman_test() { true; } # require 'pacman'; }
pacman_install() {
  get SOURCE t && die 1 FATAL "Option $( get SOURCE padSL ) is unsupported"
  get INFO t   && die 1 FATAL "Option $( get INFO   padSL ) is unsupported"
  get YES t    && die 1 FATAL "Option $( get YES    padSL ) is unsupported"
  __options="$(
                    out 'S'
    get SYNC  t  && out 'y'
    get FORCE t  && out 'f'
    get LOCAL t  && out 'u'
  )"
  _do pacman "-${options}" "$@"
}

################################################################################
# Implementing PRINT option
_do() {
  if get PRINT t; then
    ___cmd="$( for a in "$@"; do out "$( outln "${a}" | eval_escape ) "; done )"
    out "${___cmd% }; "
  else
    "$@"
  fi
}
_sudo() {
  if require "sudo"
    then _do sudo "$@"
    else _do "$@"
  fi
}

################################################################################
# Settings Manager
get() {
  IFS=, read ____b ____c ____d _____e <<EOF
${DATA#*,"${1}",},
EOF
  [ "${____b}" =  "ErRoR" ] && die 2 DEV "'${1}' is mistyped entry"
  case "${2}" in
    head)   out ",${1},${____b},${____c}," ;;
    S)      outln "${____b}";;
    L)      outln "${____c}";;
    padSL)  printf "%-${3}s\n"  "${____b}, ${____c}" ;;
    v)      outln "${____d}";;
    t)      "${____d}" ;;
    *)      die 2 DEV "\`get\` - Column '${2}' not specified or is typo'd"
  esac
}

put() {  # `set` already taken
  DATA="$(
    outln "${DATA%%${NL},"${1}",*}"
    get "${1}" head || exit "$?"; out "${2}${NL}"
    outln "${DATA#*,"${1}",*"${NL}"}"
  )" || exit "$?"
}

################################################################################
# Helpers
require() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0
  done
  return 1
}

out() { printf %s "$@"; }
outln() { printf %s\\n "$@"; }
errln() { printf %s\\n "$@" >&2; }
die() { c="$1"; errln "$2: ${name} -- $3"; shift 3; errln "$@"; exit "$c"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
