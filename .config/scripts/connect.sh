#!/bin/sh

NAME="$( basename "${0}"; printf a )"; NAME="${NAME%?a}"
WD="$( dirname "$0"; printf a )"; WD="${WD%?a}"
cd "${WD}" || { printf "Could not cd to directory of '%s'" "$0" >&2; exit 1; }
#WD="$( pwd -P; printf a )"; WD="${WD%?a}"

NL='
'

ADDR="${DOTENVIRONMENT}/addr.csv"
SSH_DIR="${HOME}/.ssh"


_CMDS="${_CMDS}help${NL}"
_help() {
  printf %s\\n "SYNOPSIS" >&2
  printf %s\\n "  ${NAME} <defined-host>" >&2
  printf %s\\n "  ${NAME} <ssh-uri>" >&2
  printf %s\\n "  ${NAME} help" >&2

  printf %s\\n "" "DESCRIPTION" >&2
  printf %s\\n "  Connects to the nickname host, defined in '${ADDR}'." >&2
  printf %s\\n "  Or connects to <ssh-uri> and displays a menu of SSH keys." >&2
  exit 1
}

[ -r "${ADDR}" ] &&_CMDS="${_CMDS}$( <"${ADDR}" cut -f1 -d',' )${NL}"

#run: sh % website
main() {
  [ "${_CMDS}" != "${_CMDS#help"${NL}"*help"${NL}"}" ] \
    && die FATAL 1 "There is a host with help as a hostname in '${ADDR}'"
  cmd="${1}"; [ "$#" -gt 0 ] && shift 1

  if    [ "${cmd}" = 'help' ]; then
    _help

  elif  [ "${cmd}" != "${cmd#*,}" ]; then
    die FATAL 1 "The <ssh-uri> '${cmd}' has a comma"

  elif  [ "${_CMDS}" != "${_CMDS#*"${NL}${cmd}${NL}"}" ]; then
    connect_to_addr_host "${cmd}" "$@"

  elif [ -z "${cmd}" ]; then
    choice="$( printf %s "${_CMDS}" | fzf )" || exit "$?"
    [ "${choice}" = "help" ] && _help
    connect_to_addr_host "${choice}" "$@"

  else
    private_key="$( list_private_keys | fzf )" || exit "$?"
    ssh -i "${private_key}" "$@" "${cmd}"
  fi
}

connect_to_addr_host() {
  line="$( <"${ADDR}" grep -F "${1}," )"
  <<EOF IFS=, read -r _ _nick host port user private_key
    ,${line}
EOF
  [ -f "${SSH_DIR}/${private_key}" ] \
    || die FATAL 1 "Private key '${private_key}' for '${1}' does not exist"
  ssh -i "${private_key}" ""
  echo "${user}@${host}" "-p" "${port}"
}

list_private_keys() {
  for f in "${SSH_DIR}"/* "${SSH_DIR}"/.*; do
    [ -e "${f}" ] || continue
    [ -e "${f}.pub" ] || continue
    f="${f#"${SSH_DIR}/"}"
    outln "${f}"
  done
}


if [ -n "${COMP_LINE}" ]; then  # `complete` is non-POSIX, so a bashism is okay
  till_cursor="${COMP_LINE:0:${COMP_POINT}}"  # @WARNING: Bashism
  cursor="${till_cursor##* }"
  set -- ${till_cursor}
  #notify.sh "${till_cursor} ${COMP_TYPE} ${COMP_POINT} ${count} $#:|${cursor}|"

  # `$0 <tab> `  First tab or on menu, empty cursor word
  if [ "${COMP_TYPE}" != 63 ] && [ -z "${cursor}" ]; then
    # If previous option accepts arguments, then only do file completions
    if [ "$#" = 1 ] && [ "${_CMDS# }" != " " ]
      then for c in ${_CMDS}; do printf %s\\n "${c}"; done
      else compgen -A file -- ""  # ${cursor} is "", file completions
    fi

  # `$0 b<tab>` First tab, non-empty cursor word
  elif [ "${COMP_TYPE}" = 64 ]; then  # TAB, first tab
    out="$( [ "$#" = 2 ] && for c in ${_CMDS}; do
      [ "${c}" != "${c#"${cursor}"}" ] && printf %s\\n "${c}"
    done )"
    if   [ -n "${out}" ]; then     printf %s\\n "${out}"
    elif [ -n "${cursor}" ]; then  compgen -A file -- "${cursor}"
    fi
  fi

  exit 0
fi

die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }

<&0 main "$@"
