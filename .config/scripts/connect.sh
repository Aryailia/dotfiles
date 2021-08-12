#/bin/sh

NAME="$( basename "${0}"; printf a )"; NAME="${NAME%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${NAME}

DESCRIPTION
  

OPTIONS
  -v, --verbose
     Good for for testing which ssh authentication methods are available
     for checking if we set server up correctly

EOF
}

ADDRESSES="${DOTENVIRONMENT}/addr.csv"
DEFAULT_KEY="${HOME}/.ssh/was"
SSH_DIR="${HOME}/.ssh"
VERBOSE=''

# Handles options that need arguments
main() {

  # Options processing
  args=''
  literal='false'
  while [ "$#" -gt 0 ]; do
    "${literal}" || case "${1}"
      in --)        literal='true'; shift 1; continue
      ;; -h|--help) show_help; exit 0

      ;; -v|--verbose) VERBOSE='-v'
      #;; -e|--example2) outln "-${2}-"; shift 1

      ;; -*) die FATAL 1 "Invalid option '${1}'. See \`${NAME} -h\` for help"
      ;; *)  args="${args} $( outln "${1}" | eval_escape )"
    esac
    "${literal}" && args="${args} $( outln "${1}" | eval_escape )"
    shift 1
  done

  #[ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"

  [ -r "${ADDRESSES}" ] || die FATAL 1 "Missing addr.csv"
  line="$( <"${ADDRESSES}" fzf ),"
  #line="test,1.1.1.1,33,user,"
  line="${line#*,}"
  ip="${line%%,*}";   line="${line#"${ip}"}"; line="${line#,}"
  port="${line%%,*}"; line="${line#"${port}"}"; line="${line#,}"
  user="${line%%,*}"; line="${line#"${user}"}"; line="${line#,}"
  port="${port:+"-p ${port}"}"

  if [ ! -e "${DEFAULT_KEY}" ]; then
    DEFAULT_KEY="$( list_files | fzf )"
  fi

  exec ssh ${VERBOSE} ${port} \
    -i "${DEFAULT_KEY}" "${user}@${ip}"
}

list_files() {
  for f in "${SSH_DIR}"/*; do
    [ -e "${f}" ] || continue
    [ -e "${f}.pub" ] || continue
    f="${f#"${SSH_DIR}/"}"
    f="${f%.sh}"
    outln "${f}"
  done
}

# Helpers
outln() { printf %s\\n "$@"; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
