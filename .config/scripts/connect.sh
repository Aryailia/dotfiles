#!/bin/sh

NAME="$( basename "${0}"; printf a )"; NAME="${NAME%?a}"
WD="$( dirname "$0"; printf a )"; WD="${WD%?a}"
cd "${WD}" || { printf "Could not cd to directory of '%s'" "$0" >&2; exit 1; }
#WD="$( pwd -P; printf a )"; WD="${WD%?a}"

NL='
'

ADDR="${DOTENVIRONMENT}/addr.csv"
SSH_DIR="${HOME}/.ssh"


_HOSTS="help${NL}"
_help() {
  printf %s\\n "SYNOPSIS" >&2
  printf %s\\n "  ${NAME} [<defined-host>]" >&2
  printf %s\\n "  ${NAME} <defined-host> [arg ...]" >&2
  printf %s\\n "  ${NAME} <ssh-uri> [arg ...]" >&2
  printf %s\\n "  ${NAME} help" >&2

  printf %s\\n "" "DESCRIPTION" >&2
  printf %s\\n "  Connects to the nickname host, defined in '${ADDR}'." >&2
  printf %s\\n "  Or connects to <ssh-uri>, prompting the user with an fzf" >&2
  printf %s\\n "  menu for which SSH private key they want to use." >&2
  printf %s\\n "  Extra args are passed as is to the ssh command." >&2
  exit 1
}

[ -r "${ADDR}" ] && _HOSTS="${_HOSTS}$( <"${ADDR}" cut -f1 -d',' )${NL}"

#run: sh % website
main() {
  [ "${_HOSTS}" != "${_HOSTS#help*"${NL}help${NL}"}" ] \
    && die FATAL 1 "There is a host with help as a hostname in '${ADDR}'"
  [ "${1}" != "${1#*,}" ] && die FATAL 1 "The \$1 <ssh-uri> '${1}' has a comma"

  case "${1}"
  in help)
    _help
  ;; "")
    choice="$( printf %s "${_HOSTS}" | fzf )" || exit "$?"
    [ "${choice}" = "help" ] && _help
    connect_to_addr_host "${choice}" "$@"
  ;; *)
    cmd="${1}"; shift 1
    if [ "${_HOSTS}" != "${_HOSTS#*"${NL}${cmd}${NL}"}" ]; then
      connect_to_addr_host "${cmd}" "$@"
    else
      connect_to_addr_host "${cmd}" "$@"
      private_key="$( list_private_keys | fzf )" || exit "$?"
      ssh -i "${private_key}" "$@" "${1}"
    fi
  esac
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
  till_curr="${COMP_LINE:0:${COMP_POINT}}"  # @WARNING: Bashism
  curr="${till_curr##* }"
  set -- ${till_curr}
  notify.sh "${till_curr} ${COMP_TYPE} ${COMP_POINT} ${count} $#:|${curr}|"

  # Do not spam completion print after the first tab
  if [ "${COMP_TYPE}" != 63 ]; then case "$#_${curr}"
    in 1_)    printf %s\\n "${_HOSTS}"
    ;; 2_?*)  for h in ${_HOSTS}; do
                [ "${h}" != "${h#"${curr}"}" ] && printf %s\\n "${h}"
              done
    #;; 2_)    compgen -A file -- ""  # ${curr} is ""
    #;; 3_?*)  compgen -A file -- "${curr}"
  esac; fi
  exit 0
fi

die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }

<&0 main "$@"
