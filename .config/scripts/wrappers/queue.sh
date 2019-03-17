#!/usr/bin/env sh
  # $0 <cmd> [<PARAMETER1> [<PARAMETER2> ...]]
# Aggregate of various useful things things to do with tmux

show_help() {
  name="$(basename "$0"; printf a)"; name="${name%??}"
  <<EOF cat - >&2
SYNOPSIS
  ${name} COMMAND [PARAMETER1] [PARAMETER2] ...
  ${name} QUEUE_NAME [PARAMETER1] [PARAMETER2] ...
  
DESCRIPTION
  Various commands for queuing downloads and/or other functions using
  task-spooler. If the first argument does not match  one of the commands as
  detailed below, then it just wraps around task-spooler by creating th tempfile
  used by a custom TS_SOCKET and running like task-spooler normally does

  Setup so that queue names are specified by "c.sh" (constants), if a new
  queue is to be added, please add it to "c.sh" as well

COMMANDS
  h, -h, help, --help
    Displays this help menu

  0, q, queue  QUEUE_NAME [PARAMETER1 [PARAMETER2 [ ... ]]]
    Forces normal task-spooler wrapper. In case for some reason the QUEUE_NAME
    that needs to be specified is defined in "c.sh" as one of the commands of
    this wrapper script to disambiguate.

  d, direct, c, curl, (w, wget, a, aria2c)  URL
    Downloads with curl to the downloads folder specified in constants.
    \`aria2c\` and \`wget\` wrappers comming soon

  s, scihub URL
    Downloads from scihub

  y, ytdl, youtube-dl  OPTIONS URL
    Use \`${name} y -h\` for more information. Uses youtube-dl to download to
    the queue folder in the downloads folder specified in constants.
EOF
}

# Helpers
prints() { printf %s "$@"; }
puts() { printf %s\\n "$@"; }
puterr() { printf %s\\n "$@" >&2; }
die() { err="$1"; shift 1; printf %s\\n "$@" >&2; exit "${err}"; }
require() { command -v "$1" >/dev/null 2>&1; }

# Dependencies
tsp=''
if   require ts;  then tsp='ts'
elif require tsp; then tsp='tsp'
else              die 1 'FATAL: Requires task spooler (ts/tsp)'
fi

constants="${SCRIPTS}/c.sh" 
[ -x "${constants}" ] || die "$?" "FATAL: '${constants}' not found"

# Queue does not need this checked, but it oh well
downloads="$("${constants}" downloads)" \
  || die "$?" "FATAL: \"downloads\" not defined in '${constants}'"
[ -d "${downloads}" ] || die "$?" "FATAL: '${downloads}' does not exist"



main() {
  cmd="$1";
  done="false"
  case "${cmd}" in
    h|-h|help|--help)  show_help; exit 0 ;;
    y|ytdl|youtube-dl)       shift 1; youtubedl "$@"; done="true" ;;
    s|scihub)                shift 1; scihub "$@"; done="true" ;;
    d|direct|c|curl|w|wget)  shift 1; direct "$@"; done="true" ;; 
    0|q|queue)               shift 1 ;;
  esac
  "${done}" || queue "$@"
}


# $0 <queue as set in constants> <tsp-arg1> <tsp-arg2> ...
# Just a wrapper for tsp
queue() {
  if [ "$#" -gt 0 ]; then
    queue="$1"; shift 1

    socket="$(${constants} "${queue}")" || die "$?" 'FATAL: Invalid queue'
    TS_SOCKET="${socket}" "${tsp}" "$@"
  else
    puterr "Just use normal \`${tsp}\` if no arguments specified"
    puterr "==============================================="
    show_help; exit 1
  fi
}

# $0 <type> <url>
# Downloads to the download folder set in `c.sh` (constants)
# Uses task spooler to queue to a specific queue, using `youtube-dl`
# To see preferences (libre and medium) check `queue-ytdl.sh`
youtubedl() {
  show_ytdl_help() {
    name="$(basename "$0"; printf a)"; name="${name%??}"
    <<EOF cat - >&2
SYNOPSIS
  ${name} youtube-dl OPTIONS URL1 [URL2 [URL3 ... ]]

DESCRIPTION
  Queues downloads with youtube-dl on to a task-spooler queue
  Prefers reasonable quality video (to save data) and libre formats

OPTIONS
  -a, --audio
    Makes all links download as audio
  -h, --help
  -v, --video
    Makes all links download as videos
  -s, --subtitles
    Check IEFT language tags, currently harded coded to English, Japanese,
    Traditional Mandarin Chinese. (You should add -v as well. Not sure how this
    interacts with -a)
EOF
  }

  # Dependency checks
  destination="${downloads}/queue"
  [ -w "${destination}" ] || die 1 "FATAL: '${destination}' not found"
  require 'youtube-dl' || die 1 "FATAL: \`youtube-dl\` not found"
  #require 'jq' || die 1 "FATAL: \`jq\` not found"

  # Branching based on first argumnt, build the options for youtube-dl
  webm360p='243'
  freelimit360p='bestvideo[height<=480][ext=webm]'
  freelimit480p='bestvideo[height<=480][ext=webm]'
  limit360p='bestvideo[height<=480]'
  limit480p='bestvideo[height<=480]'
  bestfreevideo='bestvideo[ext=webm]'
  bestfreeaudio='bestaudio[ext=webm]'

  # Process 
  url=""
  format=""
  options="--add-metadata --ignore-errors --continue"
  for arg in "$@"; do
    case "${arg}" in
      -h|--help)  show_ytdl_help; exit 0;;
      -v|--video)
	format="${webm360p}+${bestfreeaudio}"
	format="${format}/${freelimit360p}+${bestfreeaudio}"
	format="${format}/${freelimit480p}+${bestfreeaudio}"
	format="${format}/${webm360p}+bestaudio"
	format="${format}/${freelimit360p}+bestaudio"
	format="${format}/${freelimit480p}+bestaudio"
	format="${format}/${limit360p}+${bestfreeaudio}"
	format="${format}/${limit480p}+${bestfreeaudio}"
	format="${format}/${limit360p}+bestaudio"
	format="${format}/${limit480p}+bestaudio"
	format="${format}/${bestfreevideo}+${bestfreeaudio}"
	format="${format}/${bestfreevideo}+bestaudio"
	format="${format}/best"
	;;
      -a|--audio)
	format="${bestfreeaudio}/bestaudio/best"
	options="${options} --extract-audio"
	;;
      -s|--subtitle)
	options="${options} --write-sub --write-auto-sub"
	options="${options} --sub-lang en,zh-Hant,ja"
	;;
      *)
	# Confirmation when downloading a playlist or channel (save bandwith)
	# Sometimes accidentally trigger this in newsboat
        if [ "${arg}" != "${arg#*youtu}" ]; then
	  msg=""
	  [ "${arg}" != "${arg#*/channel/*}" ] && msg="channel"
	  [ "${arg}" != "${arg#*list=}" ] &&      msg="playlist"
	  if [ -n "${msg}" ]; then  # If flag triggered (is a message), then
	    puts "" "'${arg}'"
	    prints "Are you sure you the MANY videos from ${msg}? (y/n) "
	    read answer
	    if [ "${answer}" = "${answer#[Yy]}" ]; then  # Anything but 'y' 'Y'
	      puts "" "Skipping..."
	      continue
	    fi
	  fi
	fi

	url="${url} ${arg}"

	#info="$(youtube-dl  --dump-single-json --flat-playlist "${arg}")"
	#[ "$?" != "0" ] && puts "ERROR: with '${arg}'" ""
	#count="$(puts "${info}" | jq '.entries | length')"
	#exit
	#if [ -n "${count}" ] && [ "${count}" -gt 3 ]; then
	#  puts ""
	#  puts "${info}" | jq '.uploader + " - " + .title'
	#  prints "Are you sure you want to download  "${count}" videos? (y/n) "
        #  read answer
	#  if [ "${answer}" != "${answer#[Yy]}" ]; then
	#    url="${url} ${arg}"
	#  else
	#    puts "" "Skipping" ""
	#  fi
	#fi
	;;
    esac
  done

  # More validation checks
  [ -z "${format}" ] && die 1 'Please specify a format (-a or -v)'
  if [ -z "${url}" ]; then
    puterr 'ERROR: No valid urls'
    puterr '===================='
    show_help; exit 1
  fi

  # Queue the download
  queue download-queue youtube-dl ${options} -f "${format}" \
    -o "${destination}/%(uploader)s - %(title)s.%(ext)s" ${url}
  # For debugging
  #youtube-dl ${options} -f "${format}" \
    #-o "${destination}/%(uploader)s/%(title)s.%(ext)s" ${url}
}



direct() {
  url="$1"

  cd "${downloads}" || die '$?' "This should have already been checked"
  if require 'curl'; then
    if [ "${url}" != "${url%/}" ]; then
      # -p . = current directory as base, -u = only print name to STDOUT
      file="$(mktemp -p . -u directdownload.XXXXXX)"
      queue download-queue curl -L "$1" -o "${file}"
    else 
      queue download-queue curl -LO "$1"
    fi
  #elif require 'wget'; then downloader='wget'
  #elif require 'aria2c'; then downloader='aria2c'
  else
    die 1 "FATAL: \`curl\` or \`wget\` not found"
  fi
}



# $0 <url1>
# TODO: See if there is a way to distribute ${scihub}/"$@" for multiple links
scihub() {
  require 'curl' || die 1 "FATAL: \`curl\` not found"
  url="$("${constants}" scihub)/$1"
  queue download-queue curl -O "$(
    curl -s "${url}" \
      | grep 'location.href' \
      | grep -o 'http.*pdf'
    )"
}

main "$@"
