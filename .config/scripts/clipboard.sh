#!/usr/bin/env sh
  # >/dev/stdin $0 <type> <?content1> <?content2> ...
# Intended to be a portable clipboard interface
# Useful tmux as clipboard info: https://unix.stackexchange.com/questions/56477/

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  [<STDIN] ${name} OPTIONS [INPUTS ...]

DESCRIPTION
  Wrapper for the clipboard across different environments

OPTIONS
  --h, --help
    Display this help

  -r, --read
    Copy from the clipboard to STDOUT

  -w, --write INPUTS <STDIN
    Copy either STDIN or <inputs> to the clipboard
    Specifying <inputs> will ignore STDIN

  -x, --clipboard CLIPBOARD
    Use CLIPBOARD as the program. If left blank, it will try what is supported

  -v, --verbose
    Displays what clipboard is being used to STDERR

EXAMPLES
  \$ ${name} --write 'hello' 'world'                # helloworld
  \$ printf '%s\n' 'hello world' | ${name} --write  # hello world\n
  \$ ${name} --read
  \$ ${name} --help
EOF
}


##############################################################################
main() {
  name="$(basename "$0"; printf x)"; name="${name%??}"

  # Dependencies
  READ=""
  CHOICE="$(map_to '' ${ENUM_ID})"
  VERBOSE="false"

  # Options processing
  args=""; no_options="false"
  while [ "$#" -gt 0 ]; do
    "${no_options}" || case "$1" in
      --)  no_options="true"; shift 1; continue ;;
      -h|--help)  show_help; exit 0 ;;
      -x|--clipboard)  CHOICE="$(map_to "$2" "${ENUM_ID}")"; shift 1 ;;
      -r|--read)       READ="true" ;;
      -w|--write)      READ="false" ;;
      -v|--verbose)    VERBOSE="true" ;;
      *)   args="${args} $(puts "$1" | eval_escape)" ;;
    esac
    "${no_options}" && args="${args} $(puts "$1" | eval_escape)"
    shift 1
  done

  eval "set -- ${args}"
  xdg_config="${XDG_CONFIG_HOME:-"${HOME}/.config"}"
  clipboard_file="${xdg_config}/clipboard"

  # Main
  if [ "${READ}" = 'false' ]; then
    # Like GNU utils, ignore STDIN if parameter-specified input given
    { if [ "$#" -eq 0 ]
      then <&0 cat -
      else prints "$@"
    fi; } | {
      # Additional checks
      case "${CHOICE}" in
        # Without this, choosing '-x tmux' will not complain if tmux server off
        "$(map_to 'tmux' "${ENUM_ID}")")
          tmux_on || die 1 'FATAL: tmux server not running'
      esac

      notify.sh "📋"

      # Process the input to copy
      if   is_to_run 'termux-set'; then  <&0 termux-clipboard-set
      elif is_to_run 'xclip'; then       <&0 xclip -in -selection clipboard

      # Command will complain if no tmux server is running
      # `tmux_on` first so --verbose does not print
      elif tmux_on && is_to_run 'tmux'; then
        echo yo
        <&0 tmux load-buffer -b 'clipboard' -

      # Use `is_to_run` instead of else for '--verbose'
      elif is_to_run 'file'; then
        [ -w "${xdg_config}" ] || die 1 "FATAL: '${xdg_config}' not writeable"
        <&0 cat - >"${clipboard_file}"
        # Also insert into the buffer
        #require tmux && tmux_on && tmux -b 'clipboard' "${clipboard_file}"
      fi
    }

  elif [ "${READ}" = 'true' ]; then
    if   is_to_run 'termux-get'; then       termux-clipboard-get
    elif is_to_run 'xclip'; then            xclip -out -selection clipboard
    elif is_to_run 'tmux' && tmux_on; then  tmux save-buffer -b clipboard -
    elif is_to_run 'file'; then             cat "${clipboard_file}"
    fi
  else
    die 1 "FATAL: \`${name}\` requires '-r' or '-w'" "\`${name} -h\` for help"
  fi

}



##############################################################################
# Associative array implementation for choice lookups

# Makes it easier to add more aliases for the different clipboards
# map_to is where the aliases are controlled
ENUM_COMMAND="1"
ENUM_ID="2"

select_enum() {
  case "$1" in
    "${ENUM_ID}")       prints "$2" ;;  # An enum id
    "${ENUM_COMMAND}")  prints "$3" ;;  # The associated command
    *)  die 1 "DEV: Mistyped enum or did not give one" ;;
  esac
}

map_to() {
  # $1 is an alias
  # $2 is the index (fed to select_enum()) to print out
  case "$1" in
    xclip)              select_enum "$2" "1" "xclip" ;;
    termux|termux-set)  select_enum "$2" "2" "termux-clipboard-set" ;;
    termux-get)         select_enum "$2" "2" "termux-clipboard-get" ;;
    tmux)               select_enum "$2" "3" "tmux" ;;
    file)               select_enum "$2" "4" ":" ;;
    ?*)  die 1 "FATAL: Clipboard program '$1' is not supported" ;;
    *)                  select_enum "$2" "0" ":" ;;
  esac
}

is_to_run() {
  tmp_is_to_run="$(map_to "$1" "${ENUM_COMMAND}")"
  if [ "${CHOICE}" = "$(map_to '' "${ENUM_ID}")" ] \
    || [ "${CHOICE}" = "$(map_to "$1" "${ENUM_ID}")" ] \
    && require "${tmp_is_to_run}"
  then
    "${VERBOSE}" && puts "${name} - using $(
      if [ "${tmp_is_to_run}" = ":" ]
        then prints "'${clipboard_file}'"
        else prints "${tmp_is_to_run}"
      fi) as the clipboard" >&2
    return 0
  else
    return 1
  fi
}


##############################################################################
# Helpers
prints() { printf '%s' "$@"; }
puts() { printf '%s\n' "$@"; }
die() { c="$1"; shift 1; for x in "$@"; do puts "$x" >&2; done; exit "$c"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
require() { command -v "$1" >/dev/null 2>&1; }

tmux_on() { tmux info >/dev/null 2>&1; }

# $1 is the name of the actual command
# $2...  are the acceptable shorthands for the command (used by -x option)
select() {
  cmd="$1"; shift 1
  # If blank, any choice is fine. Then check if we have the command
  [ -z "${CHOICE}" ] || match_any "${CHOICE}" "$@" && require "${cmd}" \
    && { "${VERBOSE}" && puts "Using \`${cmd}\`" >&2;  true; }
}

match_any() {
  matchee="$1"; shift 1
  [ -z "${matchee}" ] && return 1
  for matcher in "$@"; do  # Literal match in case
    case "${matchee}" in "${matcher}") return 0 ;; esac
  done
  return 1
}

##############################################################################
main "$@"
