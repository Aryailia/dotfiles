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
  -a, --all
    Displays three days worth of weather (default wttr.in + AQI of today)

  -f, --force
    Forces an update even though the value has been cached. AQI in particular
    updates much more regularly (though due to non-thorough scrapping)

  -h, --help
    Display this help menu

  -o, --stdout
    Outputs to stdout without piping to \`less\`. Also silences curl
EOF
}

main() {
  # Process parameters
  force_update='false'
  all_weather='false'
  output_progress=''
  cities=""
  for arg in "$@"; do
    case "${arg}" in
      -h|--help)  show_help; exit 1 ;;
      -a|--all)     all_weather='true' ;;
      -f|--force)   force_update='true' ;;
      -o|--stdout)  output_progress='-s' ;;
      *)   cities="${cities}$(puts "${arg}" | eval_escape) " ;;
    esac
  done
  [ -n "${cities}" ] || { show_help; exit 1; }

  # Execute main logic
  eval "set -- ${cities}"
  for city in "$@"; do
    get_weather "${force_update}" "${city}" \
      | {
        if "${all_weather}"; then             <&0 cat -
        else                                  sed '18q'; fi
      } | {  # `less` for output is exceeds terminal width (eg. Android)
        if [ -n "${output_progress}" ]; then  <&0 cat -
        else                                  less --chop-long-lines; fi
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
  curl "${output_progress}" -L "${aqi_url}/${city}" | awk '/"aqi"/{
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
    aqi_file="$(mktemp)"
    weather_file="$(mktemp)"
    # Make these curls run in parallel
    get_aqi "${location}" >"${aqi_file}" &  aqi_pid="$!"
    # -s do print progress, -L follow redirects
    curl "${output_progress}" -L "${weather_url}/${city}" \
      >"${weather_file}" &    weather_pid="$!"

    wait "${aqi_pid}" "${weather_pid}"
    <"${weather_file}" sed "8i-------------- AQI: $(cat "${aqi_file}")" \
      >"${report}" || die "$?" "FATAL: Cannot write to the cached '${report}'"
    rm "${aqi_file}" "${weather_file}"
  fi
  cat "${report}"
}

main "$@"
