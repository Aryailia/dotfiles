#!/usr/bin/env sh

show_help() {
  name="$(basename "$0"; printf a)"; name="${name%??}"
  <<EOF cat - >&2
SYNOPSIS
  ${name} -c
  ${name} URL

Description
  This extracts the RSS feed from the youtube page. Should be able to enter
  either channel, video
  First one is read url from clipboard and copy output (majority of cases
  probably will work with this)

  You must feed the url with second type and it prints all options to STDOUT if
  for some reason there are several rss feeds on the youtube page

OPTIONS
  -h, --help
  -c, --clipboard
EOF
}


main() {
  arg="$1"
  [ "$#" = "0" ] && arg="$(<&0 cat -)"
  case "${arg}" in
    -h|--help)                 show_help; exit 0 ;;
    -c|--clipboard)            youtube "$(clipboard.sh -r)" | clipboard.sh -w ;;
    *youtube.com*|*youtu.be*)  youtube "${arg}" ;;
    *)                         show_help; exit 1 ;;
  esac
  # No nul-input because then cat, expecting STDIN, will block executing
}



# Helpers
youtube() {
  url="$1"
  rss_base="https://www.youtube.com/feeds/videos.xml?"
  # Five types:
  # - /user/
  # - /channel/
  # - /watch?v
  # - watch?v &list
  # - /playlist (also has ?list=
  case "${url}" in
    *[\&?]list=*)
      printf '%s%s%s' "${rss_base}" "playlist_id=" \
        "$(curl -L -s "${url}" | get_list_id_from_canonical)"
      ;;
    *)
      printf '%s%s%s' "${rss_base}" 'channel_id=' \
        "$( curl -L -s "${url}" | get_channel_id_from_meta )"
        #"$( <testfile get_channel_id_from_meta )"
      ;;
  esac
}

get_channel_id_from_meta() {
  # NOTE: grep -o is not POSIX
  <&0 awk -v FS="" 'match($0, /videos.xml\?channel_id=[^",]*/) {
    prefix = length("videos.xml?channel_id=");
    print substr($0, RSTART + prefix, RLENGTH - prefix);
    exit 0;
  }'
  #<&0 awk '/itemprop="channelId"/ {
  #  gsub(/^.*content="/, "");
  #  gsub(/".*$/, "");
  #  print($0);
  #  exit 0;  # Only print the first one
  #}'
}

# Could extract just from the url without curling but less confident in
# processing all the random meta deta in the url
# Also the string "list" may randomly be included in the metadata
get_list_id_from_canonical() {
  <&0 awk '/canonical/ {
    match($0, /<link rel="canonical" href="[^"]+">/);
    $0 = substr($0, RSTART, RLENGTH);
    gsub(/^.*list=/, "");
    gsub(/".*$/, "");
    print($0);
    exit 0;  # Only print the first one
  }'
}

#for args in "$@"; do
#  echo "${args}"
#  echo "======================="
#  #echo  'application rss'
#  #cat "$args" | awk '/application\/rss/ { print $0; }'
#  #echo  'rss'
#  #cat "$args" | awk '/rss/ { print $0; }'
#  echo  'channelID'
#  cat "$args" | awk '/itemprop="channelId"/ {
#    gsub(/^.*content="/, "");
#    gsub(/".*$/, "");
#    print($0);
#  }'
#
#  echo  'canonical'
#  cat "$args" | awk '/canonical/ {
#    match($0, /<link rel="canonical" href="[^"]+">/);
#    $0 = substr($0, RSTART, RLENGTH);
#    gsub(/^.*list=/, "");
#    gsub(/".*$/, "");
#    print($0);
#  }'
#  echo
#  echo
#done

main "$@"
