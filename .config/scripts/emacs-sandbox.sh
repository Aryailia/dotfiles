#!/usr/bin/env sh
# https://github.com/alphapapa/alpha-org/blob/master/emacs-sandbox.sh
# Credit: https://github.com/alphapapa/alpha-org/blob/master/emacs-sandbox.sh

name="$( basename "$0"; printf a )"; name="${name%?a}"
show_help() {
  [ "$#" -gt 0 ] && outln "$@" '--------'
  <<EOF cat - >&2
SYNOPSIS
  ${name} [OPTIONS]
  ${name} [-d DIR] [-O] [-P] [-H]

DESCRIPTION
  Run Emacs in a "sandbox" user-emacs-directory.  If no directory is
  specified, one is made with "mktemp -d".

OPTIONS
  --
    Special argument that prevents all following arguments from being
    intepreted as options.  Useful for separating script arguments from Emacs
    arguments

  -h, --help         This help message
  -d, --dir DIR      Use DIR as user-emacs-directory.
  -O, --no-org-repo  Don't use the orgmode.org ELPA repo.
  -P, --no-package   Don't initialize the package system.
EOF
}

# Handles options that need arguments
main() {
  # Options processing
  USER_DIR=""
  REQUIRE_ORG='true'
  REQUIRE_PACKAGES='true'

  args=''
  literal='false'
  while [ "$#" -gt 0 ]; do
    "${literal}" || case "$1" in
      --)  literal='true'; shift 1; continue ;;
      -h|--help)  show_help; exit 0 ;;

      # Canonocalise ${USER_DIR}
      -d|--user-dir)     USER_DIR="$( dirname "${2}/."; printf a )"
                         USER_DIR="${USER_DIR%?a}"; shift 1 ;;
      -O|--no-org-repo)  REQUIRE_ORG='false' ;;
      -P|--no-packages)  REQUIRE_PACKAGES='false' ;;

      -*)  show_help "'$1' is not a supported argument"; exit 1 ;;
      *)   args="${args} $( outln "$1" | eval_escape )" ;;
    esac
    "${literal}" && args="${args} $( outln "$1" | eval_escape )"
    shift 1
  done

  #[ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"

  if [ -z "${USER_DIR}" ]; then  # No argument given
    USER_DIR="$( mktemp -d )" || die 1 FATAL "Uanble to make temp dir."
  else  # Argument given but does not exist
    [ -d "${USER_DIR}" ] \
      || die 1 FATAL "Directory does not exist: '${USER_DIR}'"
  fi

  init_file="${USER_DIR}/init.el"
  args="$(
    out_arg --quick
    out_arg --eval "(set 'user-emacs-directory (file-truename \"${USER_DIR}\"))"
    out_arg --eval "(set 'user-init-file (file-truename \"${init_file}\"))"
    [ -r "${init_file}" ] && out_arg --load "${init_file}"
    out_arg --load package

    out_repo_arg      '"gnu"   . "https://elpa.gnu.org/packages/"'
    out_repo_arg      '"melpa" . "https://melpa.org/packages/"'
    "${REQUIRE_ORG}" \
      && out_repo_arg '"org"   . "https://orgmode.org/elpa/"'

    if "${REQUIRE_PACKAGES}"; then
      out_arg --eval "(package-refresh-contents)"
      out_arg --eval "(package-initialize)"
    fi
  )"

  eval "set -- ${args}"
  emacs "$@"
}

out_repo_arg() {
  out_arg --eval "$(
    printf "(add-to-list 'package-archives '(%s) t)" "$1"
  )"
}
out_arg() { for i in "$@"; do printf %s "$i" | eval_escape; printf " "; done; }
outln() { printf %s\\n "$@"; }
errln() { printf %s\\n "$@" >&2; }
die() { c="$1"; errln "$2: '${name}' -- $3"; shift 3; errln "$@"; exit "$c"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }


main "$@"
