#!/usr/bin/env sh

show_help() {
  name="$(basename "$0"; printf a)"; name="${name%??}"
  <<EOF cat - >&2
SYNOPSIS
  ${name} [OPTIONS] CITY

DESCRIPTION
  Curls wttr.in (based off of wego) for the temperature of CITY as well as
  aqicn.com for the AQI (Air Quality Index). Caches the result in \${TMPDIR}.

OPTIONS
  -h, --help
    Display this help menu

  -f, --full
    Displays three days worth of weather (default wttr.in + AQI of today)

  -u, --updates
    Forces an update even though the value has been cached. AQI in particular
    updates much more regularly (though due to non-thorough scrapping)
EOF
}

main() {
  # Process parameters
  force_update='false'
  all_weather='false'
  output_stdout='false'
  cities=""
  for arg in "$@"; do
    case "${arg}" in
      -h|--help)  show_help; exit 1 ;;
      -u|--update)  force_update='true' ;;
      -f|--full)    all_weather='true' ;;
      -o|--output)  output_stdout='true' ;;
      *)   cities="${cities}$(puts "${arg}" | eval_escape) " ;;
    esac
  done
  [ -n "${cities}" ] || { show_help; exit 1; }

  # Execute main logic
  eval "set -- ${cities}"
  for city in "$@"; do
    get_weather "${force_update}" "${city}" \
      | {
        if "${all_weather}"; then  <&0 cat -
        else                      sed '18q'; fi
      } | {  # `less` for output is exceeds terminal width (eg. Android)
	if "${output_stdout}"; then  <&0 cat -
	else                         less --chop-long-lines; fi
      }
  done
}



# Helpers
puts() { printf %s\\n "$@"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
die() { exitcode="$1"; shift 1; printf %s\\n "$@" >&2; exit "${exitcode}"; }

get_aqi() {
  city="$1"
  aqi_url='https://aqicn.org/city'
  # -s do print progress, -L follow redirects
  curl -s -L "${aqi_url}/${city}" | awk '/"aqi"/{
    match($0, "\"aqi\":[0-9]\+");
    aqi = substr($0, RSTART, RLENGTH);
    gsub(/.*:/, "", aqi);
    print(aqi);
    exit 0;
  }'
}

get_weather() {
  update="$1"
  location="$2"
  weather_url='https://wttr.in'

  report="${TMPDIR}/weather-${location}"
  # If need an update, the cached report does not exist, or it is out of date
  # `date '+%d %b'` matches with 1 Jan
  # Within first day (NR <= 17, first row) (though timezone difference makes
  # it so today will be on the second row
  if "${update}" || [ ! -f "${report}" ] \
    || <"${report}" awk "(NR <= 17 && \$0 ~ /$(date '+%d %b')/){ exit 1; }"
  then
    # -s do print progress, -L follow redirects
    curl -s -L "${weather_url}/${city}" \
      | sed "8i-------------- AQI: $(get_aqi "${location}")" \
      >"${report}" || die "$?" "FATAL: Cannot write to the cached '${report}'"
  fi
  cat "${report}"
}

main "$@"