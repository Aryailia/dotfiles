#!/bin/sh

# https://github.com/Rafficer/linux-cli-community/blob/master/protonvpn_cli/utils.py
# https://github.com/Rafficer/linux-cli-community/blob/master/protonvpn_cli/constants.py

# Test your ip address change with `curl ifconfig.me`

WD="$( dirname "$0"; printf a )"; WD="${WD%?a}"
cd "${WD}" || { printf "Could not cd to directory of '%s'" "$0" >&2; exit 1; }

exit_help() {
  NAME="$( basename "${0}"; printf a )"; NAME="${NAME%?a}"
  printf %s\\n "SYNOPSIS" >&2
  printf %s\\n "  ${NAME} <JOB> [OPTION]" >&2

  printf %s\\n "" "JOBS" >&2
  <"${NAME}" awk '
    /^  case "\$\{1\}"  # JOBS/ { run = 1; }
    /^  esac/                        { exit; }
    run && /^    in|^    ;;/ {
      sub(/^ *in /, "  ", $0);
      sub(/^ *;; /, "  ", $0);
      sub(/\) *#/, "\t", $0);
      sub(/\).*/, "", $0);
      print $0;
    }
  ' >&2
  exit 1
}

VERSION="2.2.10"
OVPN_DIR="${DOTENVIRONMENT}/data/proton"

main() {
  case "${1}"  # JOBS
    in api)   # Dumps the metadat JSON for the ProtonVPN servers
      curl_api
    ;; version)  # Check if our hard coded version, thus the api, is out-of-date
      curl_check_version
    ;; connect)  # Connect to openvpn
      connect_to_protonvpn
    ;; *|help)   exit_help
  esac

}


curl_check_version() {
  new_version="$(
    curl "https://raw.githubusercontent.com/Rafficer/linux-cli-community/master/protonvpn_cli/constants.py" \
      | awk '/^VERSION/ { gsub(/"/, "", $3); print $3; }'
  )"

  [ "${VERSION}" != "${new_version}" ] && \
    die FATAL 1 "Version is out of date"
  printf %s\\n "Version okay!" "Version: ${new_version}"
}


curl_api() {
  # See the 'util.py' from the official CLI
  # User agent is from python lib 'distro', `distro.linux_distribution()`
  # Rest API URL is from `pull_server_data()` in 'util.py'

  curl \
    -H "x-pm-appversion: LinuxVPN_${VERSION}" \
    -H "x-pm-apiversion: 3" \
    -H "Accept: application/vnd.protonmail.v1+json" \
    -H "User-Agent: ProtonVPN/${VERSION} (Linux; Arch/Rolling)" \
    "https://api.protonvpn.ch/vpn/logicals"
}


process_vpns() {
  configs="$(
    for ovpn in "${OVPN_DIR}"/*; do
      ovpn="${ovpn#"${OVPN_DIR}/"}"
      ovpn="${ovpn%.udp.ovpn}"
      ovpn="${ovpn%.tcp.ovpn}"

      printf %s\\n "${ovpn}"
    done
  )"

  curl_api \
  | jq -r '.LogicalServers
     | map(.Domain + "," + (.Load | tostring) + ","
       + (.Tier | tostring) + "," + (.Score | tostring)
     )
     | join("\n")
  ' | awk -v FS=',' -v configs="${configs}" '
    BEGIN {
      len = split(configs, ovpns, "\n")
      for (i = 1; i <= len; ++i) {
        has_ovpn[ovpns[i]] = 1;
      }
    }

    has_ovpn[$1] {
      print $0;
      has_ovpn[$1] = 2;
    }

    # Print the remaining
    END {
      for (x in has_ovpn) {
        if (has_ovpn[x] == 1) {
          print x;
        }
      }
    }
  ' | sort
}

connect_to_protonvpn() {
  printf %s\\n blah
  choice="$( process_vpns )" || exit "$?"
  choice="$( printf %s\\n "${choice}" | fzf )" || exit "$?"

  printf %s\\n "Connecting to ${choice}..."
  file="${OVPN_DIR}/${choice}.udp.ovpn"

  # prompt for password
  user="$( pass show protonvpn-user )"
  pass="$( pass show protonvpn-pass )"

  trap 'sudo killall openvpn && printf \\n%s\\n "Disconnected." >&2' INT TERM

  # sudo on the outside for password password
  printf %s "Enter sudo " >&2  # sudo password
  <<EOF sudo expect - || exit "$?"
    spawn openvpn --config {${file}}

    log_user 0
    expect -exact "Enter Auth Username:"
    send {${user}}
    send "\\r"
    expect -exact "Enter Auth Password:"
    send {${pass}}
    send "\\r"

    log_user 1
    expect {
      timeout {
        exp_continue

      } eof {
        #spawn killall openvpn
        #puts "killed"
      }
    }

    #send [exec {*}/usr/bin/env {PASSWORD_STORE_DIR=$PASSWORD_STORE_DIR} {GNUPGHOME=${GNUPGHOME}} pass show protonvpn-pass]\\r
    #log_user 1
EOF
}

outln() { printf %s\\n "$@"; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }


main "$@"
