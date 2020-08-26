#!/usr/bin/env sh

# Intended to be a portable clipboard interface
# Useful tmux as clipboard info: https://unix.stackexchange.com/questions/56477/

NAME="$( basename "$0"; printf a )"; NAME="${NAME%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  [<STDIN] ${NAME} <option> [<input1> [<input2> [ ... ]]]

DESCRIPTION
  Wrapper for the clipboard across different environments

OPTIONS
  --h, --help
    Display this help

  -r, --read
    Copy from the clipboard to STDOUT

  -w, --write
    Copy either STDIN or <inputs> to the clipboard
    Specifying <inputs> will ignore STDIN

  -x, --clipboard CLIPBOARD
    Use CLIPBOARD as the program. If left blank, it will try what is supported

  -v, --verbose
    Displays what clipboard is being used to STDERR

EXAMPLES
  \$ ${NAME} --w 'hello' 'world'
    => helloworld
  \$ printf %s\\\\n 'hello world' | ${NAME} --write
    => hello world\\n
  \$ ${NAME} --read
  \$ ${NAME} --help
EOF
}

# TODO: change this to .local
FILE_CLIPBOARD="${XDG_CONFIG_HOME:-"${HOME}/.config"}/clipboard"
NL='
'

# Handles options that need arguments
main() {
  # Flags
  READ='false'
  WRITE='false'
  CLIPBOARD_CHOICE=''
  VERBOSE='false'


  # Options processing
  args=''; literal='false'
  while [ "$#" -gt 0 ]; do
    "${literal}" || case "${1}"
      in --)  no_options="true"; shift 1; continue
      ;; -h|--help)  show_help; exit 0
      ;; -x|--clipboard)  CLIPBOARD_CHOICE="${2}"; shift 1
      ;; -r|--read)       READ="true"
      ;; -w|--write)      WRITE="true"
      ;; -v|--verbose)    VERBOSE="true"
      ;; *)   args="${args} $( outln "${1}" | eval_escape )"
    esac
    "${literal}" && args="${args} $( outln "${1}" | eval_escape )"
    shift 1
  done

  eval "set -- ${args}"

  if   "${READ}"; then
    c="$( find_clipboard "${CLIPBOARD_CHOICE}" "read" )" || exit "$?"
    case "${c}"
      in xclip)                "${c}" -out -selection clipboard
      ;; termux-clipboard-get) "${c}"
      #;; tmux)                 "${c}" save-buffer -b clipboard -
      ;; "${FILE_READ}")       "${c}" "${FILE_CLIPBOARD}"
      ;; *) die DEV 1 "Probably forgot to implement clipboard '${clipboard}'"
    esac
  elif "${WRITE}"; then
    c="$( find_clipboard "${CLIPBOARD_CHOICE}" "write" )" || exit "$?"
    notify.sh "📋" &
    read_stdin_if_no_parameters "$@" | case "${c}"
      in xclip)                "${c}" -in -selection clipboard
      ;; termux-clipboard-set) "${c}"
      #;; tmux)                 "${c}" save-buffer -b clipboard -
      ;; "${FILE_WRITE}")       "${c}" - >"${FILE_CLIPBOARD}"
      ;; *) die DEV 1 "Probably forgot to implement clipboard '${clipboard}'"
    esac
  else
    show_help
    die FATAL 1 "Specify either --write or --read"
  fi
}

FILE_READ='cat'
FILE_WRITE='cat'

# Order by first presidence to last
# 'file' is a terminating condition
CLIPBOARD_LIST="
xclip	read	xclip
xclip	write	xclip
termux	read	termux-clipboard-get
termux	write	termux-clipboard-set
file	read	${FILE_READ}
file	write	${FILE_WRITE}
	read	
	write	
"
CMD_LIST="$( printf %s "${CLIPBOARD_LIST}" | {
  while IFS= read -r line; do
    [ "${line}" !=  "${line#file}" ] && break
    printf %s\\n "${line##*	}"
  done
})"

find_clipboard() {
  [ "${1}" != "${1#*[!a-z]}" ] && die FATAL 1 \
    "The clipboard option specified '${1}' contains non a-z characters"

  clip=''
  choice_error=''
  if [ "${CLIPBOARD_LIST}" != "${CLIPBOARD_LIST#*"${NL}${1}	"}" ]; then
    clip="${CLIPBOARD_LIST#*"${NL}${1}	${2}	"}"
    clip="${clip%%${NL}*}"
  else
    choice_error="Clipboard '${1}' is not supported by \`${NAME}\`."
  fi

  if [ -z "${choice_error}" ] \
    && [ -n "${clip}" ] \
    && [ "${clip}" != 'file' ] \
    && ! require "${clip}" \
  ; then
    choice_error="Clipboard '${clip}' was not found on the current system."
  fi

  #TODO Benchmark, also benchmark with `command -v` for `require`
  # Default is the longest
  if [ -z "${choice_error}" ]; then
    for cmd in $( outln "${CMD_LIST}" | uniq ); do
    #[ -z "${choice_error}" ] && for cmd in ${CMD_LIST}; do
      if require "${cmd}"; then
        #if [ "${cmd}" = 'tmux' ] && tmux_on; then
          clip="${cmd}"
          break
        #fi
      fi
    done

    # DESIGN: File copy must be done explicitly, keep below commented
    #if [ -z "${clip}" ]; then
    #  if [ "${2}" = "read" ]
    #    then clip='cat'
    #  else
    #    else clip='printf'
    #  fi
    #fi
  fi

  if [ -n "${choice_error}" ]; then
    die FATAL 1 "${choice_error} Available clipboards:" "$(
      outln "${CLIPBOARD_LIST}" | cut -f 1 | uniq
    )"
  fi


  if [ -z "${clip}" ]; then
    die 1 "No valid clipboards found"
  elif [ "${clip}" = "${FILE_READ}" ]; then
    [ ! -r "${FILE_CLIPBOARD}" ] && die FATAL 1 \
      "Cannot read '${FILE_CLIPBOARD}'"
  elif [ "${clip}" = "${FILE_WRITE}" ]; then
    [ ! -w "${FILE_CLIPBOARD}" ] && die FATAL 1 \
      "Cannot write to '${FILE_CLIPBOARD}'"
  fi


  outln "${clip}"
}

# Like GNU utils, ignore STDIN if parameter-specified input given
read_stdin_if_no_parameters() {
  if [ "$#" = 0 ]; then
    <&0 cat -
  elif [ "$#" = 1 ]; then
    out "${1}"
  else
    out "${1}"
    shift 1
    printf \\n%s "$@"
  fi
}

#tmux_on() { tmux info >/dev/null 2>&1; }

# Helpers
out() { printf %s "$@"; }
outln() { printf %s\\n "$@"; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }
require() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0
  done
  return 1
}
#require() { command -v "${1}" >/dev/null 2>&1; }

eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
