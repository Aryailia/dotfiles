#!/usr/bin/env sh
  # $0 <option> <URL>
# Decide what program to open with. Defaults to browser

show_help() {
  name="$(basename "$0"; printf a)"; name="${name%??}"
  <<EOF cat - >&2
SYNOPSIS
  ${name} OPTIONS

DESCRIPTION
  Accepts <url> and determines what behaviour to run depending on the
  behaviour specified by <option>

OPTIONS
  -d, --download
    Download the folder specified in c.sh (constants)
    queue-ytdl.sh by defaults will download to the 'queue' subfolder

  -g, --gui
    Opens an X window outside of the terminal

  -h, --help
    Displays this help

  -t, --terminal
    Opens a new tmux pane/session a TUI/CLI program
EOF
}

# Constants
cli_browser="w3m"



# Main
is_download="false"
is_local="false"
is_external="false"

# URL domains usually are case insensitive, but users should assume sensitive
# https://www.w3.org/TR/WD-html40-970708/htmlweb.html
main() {
  type="${1}"
  url="${2}"

  # Dependencies
  constants="${SCRIPTS}/c.sh"
  queuer="${SCRIPTS}/queue.sh"
  require "${constants}" || die "FATAL: Requires '${constants}'"
  require "${queuer}" || die "FATAL: Requires '${queuer}'"
  [ -z "${url}" ] && { show_help; exit 1; }

  # Option parsing
  case "${type}" in
    -h|--help)  show_help; exit 0 ;;
    -d|--download)  is_download="true" ;;
    -t|--terminal)  is_local="true" ;;
    -g|--gui)       is_external="true" ;;
    *)  show_help; exit 1 ;;
  esac

  # Handle the link
  case "${url}" in
    # mkv, webm, mp4, certain sites -> video
    *.[Mm][Kk][Vv]|*.[Ww][Ee][Bb][Mm]|*.[Mm][Pp]4|*hooktube.com*)  video;;
    *clips.twitch.tv/*|*youtube.com/watch*|*youtu.be*|*bitchute.com*)  video;;

    #*png|*jpg|*jpe|*jpeg|*gif)
    #  setsid sxiv -a "${url}" >/dev/null 2>&1 &
    #;;

    # mp3, flac, opus, m4a
    *.[Mm][Pp]3|*.[Ff][Ll][Aa][Cc]|*.[Oo][Pp][Uu][Ss]|*.[Mm]4[Aa])
      queue_directdownload "${url}"
      #${is_download} && queue_directdownload "${url}"
      #${is_local} && 
    ;;

    *)
      if [ -f "${url}" ]; then
        ${is_download} &&  die "FATAL: '${url}' already downloaded"
        ${is_local} &&     "${EDITOR}" "${url}"
        ${is_external} &&  "${TERMINAL}" -e "${EDITOR} ${url}"
      else
        ${is_download} &&  queue_directdownload "${url}"  &
        ${is_local} &&     require "${cli_browser}" && \
          setsid "${cli_browser}" "${url}"
        ${is_external} &&  setsid "${BROWSER}" "${url}" >/dev/null 2>&1 &
      fi
    ;;
  esac
}



# Helpers
die() { printf %s\\n "$@" >&2; exit 1; }
puts() { printf %s\\n "$@"; }
require() { command -v "$1" >/dev/null 2>&1; }

video() {
  url="$1"

  # TODO: Get caca output working in busybox
  # for controlling with json? or just so that we can have multiple instances?
  # setsid mpv --input-ipc-server="${TMPDIR}/$(date +%s)" --quiet "${url}" &
  ${is_download} && queue-ytdl.sh -v "${url}"
  ${is_local} && setsid mpv --vo=caca --quiet "${url}" &
  ${is_external} && setsid mpv --quiet "${url}" &
}

queue_directdownload() {
  url="$1"
  
  filename="$(basename "${url}")"
  if [ -f "${filename}" ]; then
    die "FATAL: '${url}' already downloaded here"
  else
    # TODO: not sure if need to place one-time variable set before/after setsid
    setsid "${queuer}" download-queue curl -LO "${url}" >/dev/null 2>&1 &
  fi
}

main "$@"
