#!/usr/bin/env sh
  # source $0
# Going to be a TUI library
#https://github.com/dylanaraps/writing-a-tui-in-bash/blob/master/README.md
#https://unix.stackexchange.com/questions/426862/proper-way-to-run-shell-script-as-a-daemon
#https://unix.stackexchange.com/questions/5099/how-do-i-make-a-shell-script-that-sends-output-to-a-process
#https://stackoverflow.com/questions/25900873/write-and-read-from-a-fifo-from-two-different-script
#https://www.linuxjournal.com/content/using-named-pipes-fifos-bash

# Parameters
show_help() {
  name="$(basename "$0")"
  puts "SYNOPSIS"
  puts "  ${name} COMMAND [ARGS]"
  puts ""
  puts "DESCRIPTION"
  puts "  Uses"
  puts ""
  puts "OPTIONS"
  puts "  s, send NAME MESSAGE"
  puts "    Send a message to the name pipe that communicates with the daemon"
  puts ""
  puts "  d, daemon NAME ARGS"
  puts "    Does all the things that are "
  puts ""
  puts "  m, manager NAME ARGS"
  puts "    Called by '${name} start-daemon'"
  puts "    Necessary part of using nohup and setsid. This is called"
  puts ""
  puts "  h,help,-h,--help"
  puts "    Displays this help message"
  puts ""
  puts "EXAMPLE"
  puts '  case "$1" in'
  puts '    help)      show_help; exit 0;;'
  puts '    daemon)    shift 1; '"${name}"' daemon "${label}" $0" callback;;'
  puts '    callback)  shift 1; receive_msg "$@";;'
  puts '    *)         "${daemon_api}" send "${label}" "$@";;'
  puts '  esac'
  puts ''
  puts '  receive_msg() {'
  puts '    # do something after being trigger by the daemon'
  puts '  }'
}



# Helpers
fatal() { printf '%s\n' "$@" >&2; exit 1; }
puts() { printf '%s\n' "$@"; }



# Main
main() {
  case "$1" in
    h|help|-h|--help)  show_help; exit 0;;
    d|daemon)          shift 1; start_daemon "$@";;
    m|manager)         shift 1; daemon_manager "$@";;
    s|send)            shift 1; send_msg "$@";;
    *)                 show_help; exit 1;;
  esac
}

send_msg() {
  label="$1"
  msg="$2"

  potential_daemon_pids="$(pgrep -fa "$0" \
    | awk '{ printf("%s-%s.\n", "'"${label}"'", $1); }'
  )"

  # Find all names that might match the template
  # Filters for named pipe and strips for basename
  # Then checks if the pid in their name matches any of running instances
  filebase="$(find "${TMPDIR}" -name "${label}-*.??????" -maxdepth 1 \
    -exec sh -c '[ -p "$1" ] && printf "%s" "$(basename $1)"' _ {} \+ \
    | awk -v potentials="${potential_daemon_pids}" '
      BEGIN {
        split(potentials, file_prefixes, "\n");
        check_count = length(file_prefixes);
      }
      (1) {
        for (i = 1; i <= check_count; ++i) {
          if (index($0, file_prefixes[i]) == 1) {
            print($0);
            exit;  # Only the first one (there should only be one though)
          }
        }
      }
    '
  )"

  fifo_name="${TMPDIR}/${filebase}"
  [ -p "$fifo_name" ] || fatal 'FATAL: Daemon not running. Restart daemon'
  # NOTE: start daemon if not already started?
  
  puts "${msg}" > "$fifo_name"
  exit 0
}

start_daemon() {
  #export PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/bin
  #umask 022
  nohup setsid "$0" manager "$@" </dev/null >/dev/null 2>&1 &
  exit 0
}


daemon_manager() {
  label="$1"
  to_run="$2"
  shift 2

  cd "${TMPDIR}"
  fifo_name="${TMPDIR}/$(mktemp -u "${label}-"$$".XXXXXX")"

  # NOTE: trap TTIN TTOU INT STOP TSIP ?
  trap "rm -f ${fifo_name}" EXIT

  [ -p "${fifo_name}" ] && fatal 'fifo already exists'
  mkfifo "${fifo_name}"  # Guarenteed to be free from mktemp

  # `read` soon returns `false`, instead `break` out of infinite loop
  while :; do  
    if read <"${fifo_name}" -r line; then
      if [ "${line}" = 'quit' ]; then  # if line is quit, quit
        #printf "%s: 'quit' command received\n" "${fifo_name}"
        break
      fi
      # Run the script specified
      "${to_run}" "$@" "${line}"
    fi
  done
  exit 0  # trigger the trap
}

main "$@"
