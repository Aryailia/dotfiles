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
  queuer="queue.sh"
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
  if puts "${url}" | grep -qi -e '\.mkv$' -e '\.webm$' -e '\.mp4$' \
      -e 'youtube\.com/watch' -e 'youtu\.be/' -e 'clips\.twitch\.tv' \
      -e 'bitchute\.com' -e 'hooktube\.com'; then
    # setsid mpv --input-ipc-server="${TMPDIR}/$(date +%s)" --quiet "${url}" &
    ${is_download} && queue.sh youtube-dl --video "${url}" &
    ${is_local}    && setsid mpv --vo=caca --quiet "${url}" &
    ${is_external} && setsid mpv --quiet "${url}" &

  #elif puts "${url}" | grep -qi -e '\.bmp$' -e '\.png$' -e '\.gif$' \
  #     -e '\.tiff' -e '\.jpeg$' -e '\.jpe' -e '\.jpg$'; then
  #  setsid sxiv -a

  elif puts "${url}" | grep -qi -e '\.ogg$' -e '\.flac$' -e '\.opus$' \
       -e '\.mp3' -e '\.$' -e '\.jpe' -e '\.jpg$'; then
    ${is_download} && queue.sh direct "${url}" &
    ${is_local}    && setsid mpv --quiet "${url}" &
    ${is_external} && setsid mpv --quiet "${url}" &

  else
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
  fi
}



# Helpers
die() { printf %s\\n "$@" >&2; exit 1; }
puts() { printf %s\\n "$@"; }
require() { command -v "$1" >/dev/null 2>&1; }



main "$@"
