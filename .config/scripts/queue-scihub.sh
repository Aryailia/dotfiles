#!/usr/bin/env sh
  # $0 <url1>
# TODO: See if there is a way to distribute ${scihub}/"$@" for multiple links

scihub="$("${SCRIPTS}/c.sh" scihub)"
"${SCRIPTS}/queue-tsp.sh" download-queue curl -O "$(
  curl -s "${scihub}/$1" \
    | grep location.href \
    | grep -o 'http.*pdf'
)"
