#!/bin/sh

ADDRESSES="${DOTENVIRONMENT}/addr.csv"
KEY="${HOME}/.ssh/was"
SSH_DIR="${HOME}/.ssh"

DRYRUN='false'
VERBOSE=''
QUIET='-q'
ABSPATH=''

# Handles options that need arguments
main() {
  # Options processing
  args=''
  literal='false'
  while [ "$#" -gt 0 ]; do
    "${literal}" || case "${1}"
      in --)        literal='true'; shift 1; continue
      ;; -h|--help) show_help; exit 0
      ;; -v|--verbose)   VERBOSE='-v'; QUIET=''
      ;; -D|--dry-run)   DRYRUN='true'

      ;; -p|--path)      ABSPATH="${2}"; shift 1
      ;; -i|--identity)  KEY="${2}"; shift 1
      #;; -e|--example2) outln "-${2}-"; shift 1

      ;; -*) die FATAL 1 "Invalid option '${1}'. See \`${NAME} -h\` for help"
      ;; *)  args="${args} $( outln "${1}" | eval_escape )"
    esac
    "${literal}" && args="${args} $( outln "${1}" | eval_escape )"
    shift 1
  done

  #[ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"

  if [ ! -e "${KEY}" ]; then
    KEY="$( list_files | fzf )"
  fi

  case "$#"
    in 0)  choose_scp_URI; print_do scp ${VERBOSE} -i "${KEY}" "${URI}" ./
    ;; 1)  choose_scp_URI; print_do scp ${VERBOSE} -i "${KEY}" "${1}" "${URI}"
  esac
}

print_do() {
  if "${DRYRUN}"; then
    printf '"%s" ' "$@"
    printf \\n
  else
    "$@"
  fi
}

choose_scp_URI() {
  [ -r "${ADDRESSES}" ] || die FATAL 1 "Missing addr.csv"
  line="$( <"${ADDRESSES}" fzf --with-nth='1,4' --delimiter=, ),"
  line="${line#*,}"
  host="${line%%,*}"; line="${line#"${host}"}"; line="${line#,}"
  port="${line%%,*}"; line="${line#"${port}"}"; line="${line#,}"
  port="${port:-22}"
  user="${line%%,*}"; line="${line#"${user}"}"; line="${line#,}"

  while [ -z "${ABSPATH}" ] || [ "${ABSPATH}" = "${ABSPATH#/}" ]; do
    printf %s "Enter absolute path: "
    read -r ABSPATH
  done

  URI="scp://${user:+"${user}@"}${host}:${port}/${ABSPATH}"
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
