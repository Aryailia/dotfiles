#!/usr/bin/env sh

NAME="$( basename "${0}"; printf a )"; NAME="${NAME%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${NAME}

DESCRIPTION
  

OPTIONS
EOF
}

# Using camelCase to avoid namespace conflicts with sourced snippet file
SNIPPET_DIR="${XDG_CONFIG_HOME}/snippets"
main() {
  # Dependencies

  # Options processing
  LIST='false'
  args=''; literal='false'
  for arg in "$@"; do
    "${literal}" || case "${arg}"
      in --)         literal='true'; continue
      ;; -h|--help)  show_help; exit 0
      ;; -l|--list)  LIST='true'
      ;; -*)         die FATAL 1 "'${1}' is an invalid option"
      ;; *) args="${args} $( outln "${arg}" | eval_escape )"
    esac
    "${literal}" && args="${args} $( outln "${arg}" | eval_escape )"
  done

  [ -z "${args}" ] && die 1 FATAL 'No file extension specified'
  eval "set -- ${args}"

  snippetFile="${SNIPPET_DIR}/${1}.sh"
  [ -r "${snippetFile}" ] || die 1 FATAL "snippet file '${snippetFile}' missing"
  . "${snippetFile}" || exit "$?"
  lintSnippetNames "${SNIPPET_LIST}" "${1}" || exit "$?"

  # ${SNIPPET_LIST} will already have a newline
  if "${LIST}"; then
    out "${SNIPPET_LIST}"
  else
    choice="${2:-$( out "${SNIPPET_LIST}" | csvAlignFirstColumn | prompt )}" \
      || exit "$?"
    is_in_list="${NL}${SNIPPET_LIST}"
    if [ "${is_in_list}" != "${is_in_list#*"${NL}${choice}",}" ]; then
      "${1}_${choice}" "${1}"
    else
      die FATAL 1 \
        "There is no snippet named '${choice}'." \
        "Use \`${NAME} ${1} -l\` to list all available snippets."
    fi
  fi
}

SNIPPET_LIST=''
NL='
'

################################################################################
# Used in snippet space

addPrefixedFunction() {
  [ "${1}" != "${1#*${NL}}" ] \
    && die 1 FATAL "\`addPrefixedFunction\` - no newline in name"
  [ "${2}" != "${2#*${NL}}" ] \
    && die 1 FATAL "\`addPrefixedFunction\` - no newline in description"
  [ "${1}" != "${1#*,}" ] && die 1 FATAL "'${1}' - invalid function name"
  SNIPPET_LIST="${SNIPPET_LIST}${1},${2}${NL}"
}

ifNotRootIsReadableAndHasRegexp() {
  [ "${1}" = "/" ] || { [ -r "${1}" ] && grep -q "${2}" "${1}"; }
}

ifNotRootIsReadableAndHas() {
  [ "${1}" = "/" ] || { [ -r "${1}" ] && grep -Fq "$( "${2}" )" "${1}"; }
}
################################################################################
# Shouldn't be used in snippet space

# Need this in the same namespace as ${0}
lintSnippetNames() {
  # the snippet list ${1} will already have a trailing newline
  LintFirstCol="$( out "${1}" | cut -d ',' -f 1 )"
  outln "${LintFirstCol}" | {
    while IFS=',' read -r LintCmd LintDesc; do
      LintCmd="${2}_${LintCmd}"
      command -V "${LintCmd}" >/dev/null 2>&1 \
        || die 1 FATAL "snippet '${LintCmd}' does not exist"
    done
    true
  } || exit "$?"

  LintBad="$( outln "${LintFirstCol}" | grep -ve '^[A-Za-z_][A-Za-z0-9_]*$' )"
  [ -n "${LintBad}" ] && die 1 FATAL "Invalid snippet names:" "${LintBad}"
  return 0

  [ "$( outln "${LintFirstCol}" | uniq | wc -l )" != \
    "$( outln "${LintFirstCol}" | wc -l )" ] \
    && die 1 FATAL 'Duplicate names'
}

# Aligns second column by adding spaces before first comma
# Deletes trailing newline
csvAlignFirstColumn() (
  # the snippet list will already have a trailing newline
  _len=0
  #_input="$( cat - )"
  _input=''
  while IFS=',' read -r _first _rest; do
    _input="${_input}${_first},${_rest}${NL}"
    [ "${#_first}" -gt "${_len}" ] && _len="${#_first}"
  done

  outln "${_input%${NL}}" | while IFS=',' read -r _first _rest; do
    printf "%-${_len}s,%s\\n" "${_first}" "${_rest}"
  done

)

prompt() {
  require fzf && { <&0 promptFzf; return 0; }
  pick "$( cat - )"
}
promptFzf() {
  { outln; <&0 sed 's/,/   - /'; } \
    | fzf --delimiter='-' --nth="1" \
    | sed 's/ .*$//'
}

RED='\001\033[31m\002'
CYAN='\001\033[36m\002'
CLEAR='\001\033[0m\002'
pc() { printf %b "$@" >/dev/tty; }
promptTest() {
  pc "${2}"; read -r value; pc "${CLEAR}"
  while outln "${value}" | grep -qve "${1}"; do
    pc "${3:-"${2}"}"; read -r value
    pc "${CLEAR}"
  done
  printf %s "${value}"
}

pick() {
  [ -z "${1}" ] && return 1
  choice="$( promptTest "$(
      outln "${1}" | awk '
        (NR == 1){ printf("^1$"); }
        (NR > 1){ printf("%s", "\\|^" NR "$"); }
      '
    )" "$(
      outln "${1}" | awk '{ print "'"${CYAN}"'" NR "'"${CLEAR}"') " $0 }'
      out "Enter your choice: ${CYAN}"
    )" "${RED}Invalid option${CLEAR}"
  )"
  outln "${1}" | sed -n "${choice}p"
}


################################################################################
# Helpers
require() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/${1}" ] && [ -x "${dir}/${1}" ] && return 0
  done
  return 1
}
out() { printf %s "$@"; }
outln() { printf %s\\n "$@"; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
