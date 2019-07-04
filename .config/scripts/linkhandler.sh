#!/usr/bin/env sh
  # $0 <option> <URL>
# Decide what program to open with. Defaults to browser

name="$(basename "$0"; printf a)"; name="${name%??}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name} [OPTIONS] [URL1 [URL2 [...]]]

DESCRIPTION
  Accepts <url> and determines what behaviour to run depending on the
  behaviour specified by <option>. You can also pass a url via STDIN instead

OPTIONS
  -c, --copy
    Copies the command generatd into the clipboard (uses clipboard.sh) and does
    not execute the command

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


# Choosing programs specifically
# Terminal browser wrapper
#MASTODAN_HANDLER=""
#STREAM=""



# Main
is_copy="false"
is_download="false"
is_local="false"
is_external="false"

# URL domains usually are case insensitive, but users should assume sensitive
# https://www.w3.org/TR/WD-html40-970708/htmlweb.html
main() {
  # Dependencies
  constants="c.sh"
  queuer="queue.sh"
  copy="clipboard.sh"
  require "${constants}" || die 1 'FATAL' "Requires '${constants}'"
  require "${queuer}" || die 1 'FATAL' "Requires '${queuer}'"

  # Option parsing
  urls=""
  doubledash="false"
  while [ "$#" -gt 0 ]; do
    "${doubledash}" || case "$1" in
      --)  doubledash="true"; shift 1; continue ;;

      -h|--help)      show_help; exit 0 ;;
      -c|--copy)      is_copy="true"
                      require "${copy}" || die 1 'FATAL' "Requires '${copy}'" ;;
      -d|--download)  is_download="true" ;;
      -t|--terminal)  is_local="true" ;;
      -g|--gui)       is_external="true" ;;

      *)   urls="${urls} $(puts "$1" | eval_escape)" ;;
    esac
    "${doubledash}" && urls="${urls} $(puts "$1" | eval_escape)"
    shift 1
  done

  eval "set -- ${urls}"

  # At least one option specified and at least one url given
  if "${is_download}" || "${is_local}" || "${is_external}"
    then if [ "$#" -gt 0 ]; then handle "$@"; else handle "$(cat -)"; fi
    else show_help; exit 1
  fi
}

handle() {
  [ "$*" = "" ] && die 1 'FATAL' 'no url provided'
  for url in "$@"; do
    # Handle the link
    if puts "${url}" | grep -qi -e '\.mkv$' -e '\.webm$' -e '\.mp4$' \
        -e 'youtube\.com/watch' -e 'youtu\.be/' -e 'clips\.twitch\.tv' \
        -e 'bitchute\.com' -e 'hooktube\.com'; then
      # setsid mpv --input-ipc-server="${TMPDIR}/$(date +%s)" --quiet "${url}" &
      d "${queuer}" youtube-dl --video "${url}" &
      t mpv --vo=caca --quiet "${url}"
      is_android && g setsid mpv --quiet "${url}" &
      is_android || g "${BROWSER}" "${url}"

    #elif puts "${url}" | grep -qi -e '\.bmp$' -e '\.png$' -e '\.gif$' \
    #     -e '\.tiff' -e '\.jpeg$' -e '\.jpe' -e '\.jpg$'; then
    #  setsid sxiv -a

    elif puts "${url}" | grep -qi -e '\.ogg$' -e '\.flac$' -e '\.opus$' \
         -e '\.mp3' -e '\.$' -e '\.jpe' -e '\.jpg$'; then
      d "${queuer}" direct "${url}" &
      t mpv --quiet "${url}"
      is_android && g setsid mpv --quiet "${url}" &
      is_android || g "${BROWSER}" "${url}"

    elif puts "${url}" | grep -qi -e '\.pdf$'; then
      d "${queuer}" direct "${url}" &
      t pdftotext --nopgbrk - | less  # The final dash prints to STDOUT
      g zathura "${url}" &

    elif puts "${url}" | grep -qi -e 'reddit\.com/$'; then
      d "${queuer}" direct "${url}" &
      t rtv "${url}"
      g setsid "${BROWSER}" "${url}" >/dev/null 2>&1 &

    else
      if [ -f "${url}" ]; then
        d die 1 'FATAL' "'${url}' already downloaded"
        t "${EDITOR}" "${url}"
        g "${TERMINAL}" -e "${EDITOR} ${url}"
      else
        d "${queuer}" direct "${url}" &
        t browser.sh run 'w3m' "${url}"
        g browser.sh run "${BROWSER}" "${url}"
      fi
    fi
  done
}



# Helpers
require() {
  for dir in $(printf %s "${PATH}" | tr ':' '\n'); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0
  done
  return 1
}
die() {
  c="$1"; puts "$2: '${name}' -- $3" >&2; shift 3
  puts "$@" >&2; exit "$c"
}
puts() { printf %s\\n "$@"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

# Copy require checked in `main` during option handling
d() { ${is_download} && if ${is_copy}; then "${copy}" -w "$*"; else "$@"; fi; }
t() { ${is_local}    && if ${is_copy}; then "${copy}" -w "$*"; else "$@"; fi; }
g() { ${is_external} && if ${is_copy}; then "${copy}" -w "$*"; else "$@"; fi; }

is_android() { uname -o | grep -q 'Android'; }

main "$@"
