#!/usr/bin/env sh
  # $0 <type> <url>
# Downloads to the download folder set in `constants.sh`
# Uses task spooler to queue to a specific queue, using `youtube-dl`
# To see preferences (libre and medium) check `queue-ytdl.sh`

# Parameters
type="$1"
url="$2"

show_help() {
  name="$(basename $0)"
  puts "SYNOPSIS"
  puts "  ${name} OPTIONS"
  puts ""
  puts "DESCRIPTION"
  puts "  Queues downloads with youtube-dl on to a task-spooler queue"
  puts "  Prefers reasonable quality video (to save data) and libre formats"
  puts ""
  puts "OPTIONS"
  puts "  -a, --audio URL"
  puts "  -h, --help"
  puts "  -v, --video URL"
}



# Helper
puts() { printf '%s\n' "$@"; }
fatal() { printf '%s\n' "$@"; exit 1; }



# Dependency checks
constants="${SCRIPTS}/constants.sh"
[ -x "${constants}" ] || fatal "FATAL: '${constants}' not found"
destination="$(${constants} downloads)"
[ -w "${destination}" ] || fatal "FATAL: ${destination} not found"
tsp_queue="${SCRIPTS}/queue-tsp.sh"
[ -x "${tsp_queue}" ] || fatal "FATAL: '${tsp_queue}' not found"

command -v 'youtube-dl' >/dev/null 2>&1 || fatal 'FATAL: `youtube-dl` not found'



# Branching based on first argumnt, build the options for youtube-dl
webm360p='243'
bestfreevideo='bestvideo[ext=webm]'
bestfreeaudio='bestaudio[ext=webm]'
limit480p='bestvideo[height<=480]'
freelimit480p='bestvideo[height<=480][ext=webm]'

format=""
options="--add-metadata --ignore-errors --continue"
case "${type}" in
  -h|--help)  show_help; exit 0;;
  -v|--video)
    format="${webm360p}+${bestfreeaudio}"
    format="${format}/${webm360p}+bestaudio"
    format="${format}/${freelimit480p}+bestaudio"
    format="${format}/${bestfreevideo}+${bestfreeaudio}"
    format="${format}/${limit480p}+${bestfreeaudio}"
    format="${format}/best"
    ;;
  -a|--audio)
    format="${bestfreeaudio}/bestaudio/best"
    options="${options} --extract-audio"
    ;;
  *)  show_help; exit 1;;
esac

# Queue the download
"${tsp_queue}" download-queue youtube-dl ${options} -f "${format}" \
  -o "${destination}/%(uploader)s - %(title)s.%(ext)s" "${url}"
