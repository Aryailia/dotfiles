#!/bin/sh
  # $0 <type> <url>
# Downloads to the download folder set in `constants.sh`
# Uses task spooler to queue to a specific queue, using `youtube-dl`
# To see preferences (libre and medium) check `queue-ytdl.sh`

# Parameters
type="$1"
url="$2"

show_help() {
  printf '%s\n' \
    "Usage: $(basename $0) <type> <url>\n" \
    "" \
    "Prefers reasonable quality video (to save data) and libre formats" \
    "" \
    "Options:" \
    "<type> can be audio/a/video/v" \
    "<url> is the url that will be fed to youtube-dl" \
  ''
}



# Helper
fatal() { printf '%s\n' "$@"; exit 1; }



# Dependency check
constants="${SCRIPTS}/constants.sh"
[ -x "${constants}" ] || { fatal "ERROR: '${constants}' not found"; }
destination="$(${constants} downloads)"
[ -w "${destination}" ] || { fatal "ERROR: ${destination} not found"; }
tsp_queue="${SCRIPTS}/queue-tsp.sh"
[ -x "${tsp_queue}" ] || { fatal "ERROR: '${tsp_queue}' not found"; }

command -v 'youtube-dl' >/dev/null 2>&1 || {
  echo 'Error: Requires `youtube-dl`. Aborting'
  exit 1
}



# Branching based on first argumnt, build the options for youtube-dl
webm360p='243'
bestfreevideo='bestvideo[ext=webm]'
bestfreeaudio='bestaudio[ext=opus]'
limit480p='bestvideo[height<=480]'
freelimit480p='bestvideo[height<=480][ext=webm]'

format=""
options="--add-metadata --ignore-errors --continue"
case "${type}" in
  -h) show_help; exit 0;;
  v|video)
    format="${webm360p}+${bestfreeaudio}"
    format="${format}/${webm360p}+bestaudio"
    format="${format}/${freelimit480p}+bestaudio"
    format="${format}/${bestfreevideo}+${bestfreeaudio}"
    format="${format}/${limit480p}+${bestfreeaudio}"
    format="${format}/best"
    ;;
  a|audio)
    format="${bestfreeaudio}/bestaudio/best"
    options="$options --extract-audio"
    ;;
  *) show_help; exit 1;;
esac

# Queue the download
"${tsp_queue}" download-queue /bin/youtube-dl ${options} -f "$format" \
  -o "${destination}/%(uploader)s - %(title)s.%(ext)s" "${url}"
