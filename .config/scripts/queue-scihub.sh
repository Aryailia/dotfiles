#!/bin/sh
  # $0 <url1>
# TODO: See if there is a way to distribute ${scihub}/"$@" for multiple links

scihub="$(${SCRIPTS}/constants.sh scihub)"
"${SCRIPTS}/queue-tsp.sh" download-queue /bin/curl -O $(
  /bin/curl -s "${scihub}/$1" \
    | grep location.href \
    | grep -o http.*pdf
)
