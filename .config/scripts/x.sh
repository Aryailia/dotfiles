#!/usr/bin/env sh

WALLPAPER="${HOME}/.config/wallpaper.png"

name="$( basename "$0"; printf a )"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name}

DESCRIPTION
  
EOF
}



# Handles single character-options joining (eg. pacman -Syu)
main() {
  case "${1}" in
    run-and-return-pid)          shift 1; run_and_return_pid "$@" ;;
    wall|setwall|set-wallpaper)  shift 1; set_wallpaper "$@" ;;
    send|send-keys)              shift 1; send_keys "${@}";;
    *) echo did not match anything ;;
  esac

}

# Does a diff of the `pgrep` of ${1} before and after running "$@{1 ..}"
run_and_return_pid() {
  # $1: command to pgrep
  # $2 $3 ...: command to launch whatever program
  grep_by="$1"; shift 1
  before="$( pgrep "${grep_by}" )"  # Do not think we need to sort
  [ "$#" -gt 0 ] || die 1 FATAL 'Provide shellscript to run'
  "$@" >/dev/null 2>&1
  after="$( pgrep "${grep_by}" )"
  [ "${before}" != "${after}" ] || die 1 FATAL \
    "Your shellscript does not seem to launch \`$1\`" \
    "or \`pgrep\` is not finding it"

  printf %s\\n "${before}" | awk -v after="${after}" '
    BEGIN {
      len = split(after, list, "\n *");
      for (i = 1; i <= len; i += 1) {
        uniqued[list[i]] = 1;
      }
    }
    {
      if (uniqued[$0]) {
        uniqued[$0] = 0;
      } else {
        len += 1;
        list[len] = $0;
        uniqued[$0] = 1;
      }
    }
    END {
      for (i = 1; i <= len; i += 1) {
        if (uniqued[list[i]]) {
          print list[i];
        }
      }
    }
  '
}



set_wallpaper() {
  [ -n "${1}" ] && [ -r "${1}" ] && cp "${1}" ~/.config/wallpapper.png \
    && notify-send -i "${WALLPAPER}" "Wallpaper set."
  xwallpaper --zoom "${WALLPAPER}"
}


send_keys() {
  program="${1}"; shift 1

  # xdotool search always returns many (for reasons I do not know)
  # Narrow to 
  window_id="$(
    xdotool search --pid "$( pgrep "${program}" )" | xargs -L 1 sh -c '
      xprop -id "${1}" "WM_STATE" | grep -qv "not found" && echo "${1}"
    ' _ #| sed 1q  # In case it appears more than once?
  )"

  # --onlyvisible works inconsistantly if window in different workspace
  #xdotool search --pid "$( pgrep "${program}" )" --onlyvisible \
  #  | xargs -I '{}' xdotool key --window "{}" "${@}"

  xdotool key --window "${window_id}" "${@}"

  # Epiphany for instances needs windowactivate first
  # Perhaps handle those on an individual basis
  #xdotool windowactivate "${window_id}" key "${@}"

}


# Helpers
puts() { printf %s\\n "$@"; }
errln() { printf %s\\n "$@" >&2; }
die() { c="$1"; errln "$2: '${name}' -- $3"; shift 3; errln "$@"; exit "$c"; }


eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
