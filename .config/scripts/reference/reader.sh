#/usr/bin/env sh
  # stuff
#

# Helepers
fatal() { printf '%s\n' "$@"; exit 1; }
require() { [ "$1" "$2" ] || fatal "FATAL: Requires $2 to run"; }



# Dependencies
daemon_api="${SCRIPTS}/lib/daemon.sh"
require -x "${daemon_api}"



# Constants
label="$(basename $0)"
label="${label%.*}"



# Parameters
show_help() {
  name="$(basename "$0")"
  puts "SYNOPSIS"
  puts "  ${name} [OPTIONS]"
  puts "  ${name} MESSAGE"
  puts ""
  puts "DESCRIPTION"
  puts "  Starts"
  puts ""
  puts "OPTIONS"
  puts "  -d, --daemon"
  puts "  -h, --help"
  puts " "
}

main() {
  case "$1" in
    h|help|-h|--help)   show_help; exit 0;;
    d|daemon-start)     shift 1; ${daemon_api} daemon "${label}" "$0" --r;;
    -r|--recieve)       shift 1; receive_msg "$@";;
    *)                  "${daemon_api}" send "${label}" "$@";;
  esac
}

receive_msg() {
  mktemp 'asdf.XXXXXX'
}

main "$@"
