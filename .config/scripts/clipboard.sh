#/bin/sh

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

  -x, --clipboard [CLIPBOARD]
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
CLIPBOARDS="${NL}"

# Handles options that need arguments
main() {
  # Flags
  CMD=""
  CLIPBOARD_CHOICE=''
  VERBOSE='false'

  # Options processing
  args=''; literal='false'
  while [ "$#" -gt 0 ]; do
    "${literal}" || case "${1}"
      in --)  no_options="true"; shift 1; continue
      ;; -h|--help)  show_help; exit 0
      ;; -r|--read)       CMD="read"
      ;; -w|--write)      CMD="writ"
      ;; -v|--verbose)    VERBOSE="true"
      ;; -x|--clipboard)
        if [ "$#" -gt 1 ]; then
          CLIPBOARD_CHOICE="${2}"; shift 1
        else
          CLIPBOARD_CHOICE="$( prompt \
            "[0-9][0-9]*" \
            "$( printf %s "${CLIPBOARDS#?}" | nl )" \
            "Enter the clipboard you want: "
          )"
        fi
      ;; *)   args="${args} $( outln "${1}" | eval_escape )"
    esac
    "${literal}" && args="${args} $( outln "${1}" | eval_escape )"
    shift 1
  done

  eval "set -- ${args}"
  if [ -n "${CMD}" ]; then
    choice=""
    if [ -z "${CLIPBOARD_CHOICE}" ]; then
      for board in ${CLIPBOARDS}; do
        "${board}_need" && choice="${board}" && break
      done
    else
      choice="${CLIPBOARD_CHOICE}"
    fi

    [ "${CLIPBOARDS#*"${NL}${choice}${NL}"}" != "${CLIPBOARDS}" ] \
      || die FATAL 1 "'${choice}' is an unsupported clipboard."
    case "${CMD}"
      in "read")  "${choice}_read"
      ;; "writ")  read_stdin_if_no_parameters "$@" | "${choice}_writ"
                  notify.sh "📋"
      ;; *)       die DEV 1 "Should only be read or writ"
    esac
  else
    die FATAL 1 "Specify either --write or --read"
  fi
}

#run: clipboard.sh -r -x tmux

# The order of these clipboards is the priority order
# Name just add to ${CLIPBOARDS} as to be the same as the functions

CLIPBOARDS="${CLIPBOARDS}winclip${NL}"
winclip_need() { require "clip.exe"; }
# BUG: powershell.exe changes font for all WSL terminals
#      You must set WSL console font to cmd.exe default (lucida console)
# https://github.com/microsoft/terminal/issues/367
# powershell.exe always adds \r\n
winclip_read() {
  t="$( powershell.exe -noprofile Get-Clipboard )" # strip \n
  printf %s "${t%?}"                               # strip \r
}
winclip_writ() { <&0 clip.exe; }

# Although WSL has xclip, it does not really interface with Windows' clipboard
CLIPBOARDS="${CLIPBOARDS}xclip${NL}"
xclip_need() { require "xclip"; }
xclip_read() { xclip -out -selection clipboard; }
xclip_writ() { <&0 xclip -in -selection clipboard; }

CLIPBOARDS="${CLIPBOARDS}termux${NL}"
termux_need() { require "termux-clipboard-get"; }
termux_read() { <&0 termux-clipboard-get; }
termux_writ() { <&0 termux-clipboard-set; }

CLIPBOARDS="${CLIPBOARDS}tmux${NL}"
tmux_need() { [ -n "${TMUX}" ]; }
tmux_read() { tmux show-buffer -b clipboard; }
tmux_writ() { <&0 tmux load-buffer -b clipboard -; }



# Like GNU utils, ignore STDIN if parameter-specified input given
read_stdin_if_no_parameters() {
  if [ "$#" = 0 ]; then
    <&0 cat -
  elif [ "$#" = 1 ]; then
    printf %s "${1}"
  else
    printf %s "${1}"
    shift 1
    printf \\n%s "$@"
  fi
}

# Helpers
outln() { printf %s\\n "$@"; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }
require() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/${1}" ] && [ -x "${dir}/${1}" ] && return 0
  done
  return 1
}


eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
