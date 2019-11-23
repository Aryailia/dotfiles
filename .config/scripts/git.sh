#!/usr/bin/env sh

name="$( basename "$0"; printf a )"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name}

DESCRIPTION
  Various git commands that are difficult to replicate

SUBCOMMANDS
  subtreepush <subtree_folder>
    This is for the
EOF
}



NL='
'

CYAN='\001\033[36m\002'
CLEAR='\001\033[0m\002'

main() {
  [ "$#" = 0 ] && eval "set -- $( prompt '.*' "$( outln \
    "${CYAN}help${CLEAR}" \
    "${CYAN}extract${CLEAR} <source> [<repo_url>] [<repo_branch>] [<dest>]" \
    "${CYAN}init_subtree${CLEAR} <dir> [<repo_url>] [<repo_branch>] " \
    "${CYAN}subtree_push${CLEAR} <dir> [<repo_url>] [<repo_branch>]" \
    "${CYAN}zfreshstart${CLEAR} - just for debugging" \
    "Enter one of the options: ${CYAN}" \
  )" )"
  cmd="${1}"; shift 1
  case "${cmd}" in
    h*)  show_help; exit 0 ;;

    e*)  split_into_local_subtree "$@" ;;
    i*)  subtree_init "$@" ;;
    s*)  subtree_push "$@" ;;
    z*)  setup_test ;;

    *)   show_help; exit 1 ;;
  esac
}

subtree_push() {
  # $1: directory of the subtree to push
  RELPATH=""  # Guard against random side-effects
  cd_home_and_print_path_to_RELPATH "${1}"

  _config="${RELPATH}/.gitconfig"
  _url="${2:-"$( git config -f "${_config}" --get remote.origin.url \
    || prompt '.*' 'Enter subtree repository url:    '
  )"}"
  _branch="${2:-"$( git config -f "${_config}" --get push.default \
    || prompt '.*' "Enter branch (default 'master'): "
  )"}"
  git subtree push --prefix "${RELPATH}" "${_url}" -- "${_branch:-master}"
}

setup_test() {
  rm -rf ~/interim/df_test
  cp -r ~/interim/filesdot ~/interim/df_test
}


# `git log --follow -- <path>` is checking commits that touch '<path>'
# `git rev-list --count <branch>` for debugging `git branch-filter`
#
# Tutorial on subtree:      https://www.atlassian.com/git/tutorials/git-subtree
# Similar use case to ours: https://help.github.com/en/github/using-git
#   /splitting-a-subfolder-out-into-a-new-repository
# Subtree explanation:      https://stackoverflow.com/questions/32407634
# Step-by-step walkthrough: https://stackoverflow.com/questions/359424
# More history commands:    https://stackoverflow.com/questions/2100907
################################################################################
# Handles
split_into_local_subtree() {
  # ${1}: File to split into subtree
  # ${2}: url to the repository to push the new subtree to
  # ${3}: branch of the subtree remote repository to push to
  # ${4}: path that the subtree locally should reside

  RELPATH=""  # Guard against random side-effects
  cd_home_and_print_path_to_RELPATH "${1}"
  _relpath="${RELPATH}"

  # Get temporary branch name to store the history edits
  _current_branch="$( git branch | grep '^\*' | cut -d ' ' -f 2 )"
  _temp_branch="$( git branch --format "%(refname:lstrip=2)" | awk '
    { names[$1] = 1; }
    END {
      output = "temp";
      while (names[output]) {
        output = output "1"
      }
      print output;
    }
  ' )"

  errln "" "Creating temporary branch '${_temp_branch}' ..."
  git checkout -b "${_temp_branch}"  # Duplicates the current branch
  # TODO: Check all commit tags to see if ${_into} exists and uniquify it
  _into="$( mktemp --directory --tmpdir='.' )" \
    || die 1 FATAL 'Cannot make temp dir'

  errln "" "Filtering history to just that file ..."
  # This temp environment var suppresses the annoying warning
  FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --force --tree-filter \
    "mkdir -p \"${_into}\" && git mv -k -f \"${_relpath}\" \"${_into}\"" \
    || exit "$?"

  # If target was a directory, then redirect to it
  # Using ${_relpath} instead of ${1} because santized (else 'hello/' -> '')
  if [ -d "${1}" ]
    then _into2="${_into}/${_relpath##*/}"
    else _into2="${_into}"
  fi
  FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --force \
    --subdirectory-filter "${_into2}" \
    || exit "$?"

  # Push subtree to its remote and then cleanup temp branch
  errln "" "Push new subtree-to-be to remote repository"
  _url="${2:-"$( prompt '.*'      'Repo url (blank to cancel):    ' )"}"
  if [ -n "${_url}" ]; then
    _branch="${3:-"$( prompt '.*' "Branch (defaults to 'master'): " )"}"
    _branch="${_branch:-master}"
    errln
    git push "${_url}" "${_temp_branch}:${_branch}" || exit "$?"
    git checkout "${_current_branch}" || exit "$?"
    git branch -D "${_temp_branch}" || exit "$?"

    # Add subtree back into to the original branch
    _path="${4:-"$( prompt '^$\|^[^.].*\|^\.[^.].*\|^\.\...*' "$( out \
      "${NL}Add subtree back into this project at the folder specified by" \
      " the following path. This path is relative to the project home." \
      " NOTE: Both '.' and '..' are invalid paths" \
      "${NL}Enter path (blank to cancel): " \
    )" )"}"
    if [ -n "${_path}" ]; then
      git subtree add --squash --prefix "${_path}" "${_url}" "${_branch}" \
        || exit "$?"
      subtree_init "${_path}" "${_url}" "${_branch}"  # overwrites ${RELPATH}

      # Symlink
      case "$( prompt '.*' 'Remove old and symlink to new? (y/N): ' )" in y|Y)
        rm -r "${_relpath}"
        if [ -d "${1}" ]
          then ln -s "${_path}" "${_relpath}"
          else ln -s "${_path}/${_relpath##*/}" "${_relpath}"
        fi ;;
      esac
    fi
  else
    errln "NOTE: Branch for the subtree '${_temp_branch}' still exists"
    git checkout "${_current_branch}" || exit "$?"
  fi
}

subtree_init() {
  cd_home_and_print_path_to_RELPATH "${1}"  # For 'LICENSE' (replaces ${1} use)

  # Make '.gitconfig'
  __config="${RELPATH}/.gitconfig"
  __url="${2:-"$( prompt '.*'    'Enter remote subtree repo url:  ' )"}"
  git config -f "${__config}" --add remote.origin.url "${__url}" || exit "$?"
  __branch="${3:-"$( prompt '.*' "Enter branch (default 'master': " )"}"
  __branch="${__branch:-master}"
  git config -f "${__config}" --add push.default "${__branch}" || exit "$?"

  [ -e "LICENSE" ] && cp LICENSE "${RELPATH}"  # Exists in project home
  out '' >"${RELPATH}/README.adoc"
}

# `cd` to the git project home of ${1} and print the new relative path to ${1}
# Supports processing from outside the git folder too (git errors normally)
cd_home_and_print_path_to_RELPATH() {
  [ -e "${1}" ] || die 1 FATAL "The provided path '${1}' does not exist"
  __source="$( absolute_path "${1}"; printf a )"; __source="${__source%a}"
  __dir="$( dirname "${1}"; printf a )"; __dir="${__dir%?a}"
  cd "${__dir}" || exit 2  # This probably does not happen

  __home="$( git rev-parse --show-toplevel || return "$?"; printf a )" \
    || die "$?" FATAL "'${1}' is not a git repo"; __home="${__home%?a}"
  cd "${__home}" || exit 2  # This probably does not happen

  # Get the path of ${1} relative to the git project home
  __relpath="${__source#"${__home}"}"
  if [ -z "${__relpath}" ]
    then __relpath="."
    else __relpath="${__relpath#/}"
  fi
  [ -e "${__relpath}" ] || die 1 FATAL 'Something went wrong with the pathing'

  RELPATH="${__relpath}"
}

absolute_path() (
  dir="$( dirname "${1}"; printf a )"; dir="${dir%?a}"
  cd "${dir}" || exit "$?"
  wdir="$( pwd -P; printf a )"; wdir="${wdir%?a}"
  base="$( basename "${1}"; printf a )"; base="${base%?a}"
  output="${wdir}/${base}"
  [ "${output}" = "///" ] && output="/"
  printf %s "${output%/.}"
)

prompt() {
  pc "${2}"; read -r value; pc "${CLEAR}"
  while outln "${value}" | grep -qve "$1"; do
    pc "${3:-"$2"}"; read -r value
    pc "${CLEAR}"
  done
  printf %s "${value}"
}


pc() { printf %b "$@" >/dev/tty; }
out() { printf %s "$@"; }
outln() { printf %s\\n "$@"; }
err() { printf %s "$@" >&2; }
errln() { printf %s\\n "$@" >&2; }
die() { c="$1"; errln "$2: '${name}' -- $3"; shift 3; errln "$@"; exit "$c"; }

main "$@"
