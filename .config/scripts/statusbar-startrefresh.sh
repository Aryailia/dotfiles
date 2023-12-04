#!/usr/bin/env sh

name="$( basename "$0"; printf a )"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name} <OPTION>

DESCRIPTION
  If no option is given, it this uses \`pgrep\` to search for which window
  manager is running and runs the appropriate branch

OPTIONS
  -p, --print
    Just prints the status bar to STDOUT without updating

  --i3
    Run this in the i3 config as \`bar { status_command exec ${name} --i3 }\`

EOF
}

COMMAND='0'
ENUM_PRINT='1'
ENUM_I3='2'
ENUM_DWM='3'

main() {
  # Options processing
  for arg in "$@"; do case "${arg}" in
    -h|--help)   show_help; exit 0 ;;
    -p|--print)  COMMAND="${ENUM_PRINT}" ;;
    --i3)        COMMAND="${ENUM_I3}" ;;
  esac done


  case "${COMMAND}" in
    "${ENUM_I3}")     run_or_update_i3 ;;
    "${ENUM_DWM}")    echo WIP; exit 1 ;;
    "${ENUM_PRINT}")  status ;;
    *)
      if   pgrep i3 >/dev/null 2>&1; then  run_or_update_i3
      #elif pgrep i3; then run_or_update_i3
      else  printf %s\\n "FATAL: ${name} -- No window manager supported" >&2
      fi ;;
  esac
}


sleep_timer='60'
set_sleep_timer() {
  #sleep_timer='60'
  notify.sh 'hello'
}


run_or_update_i3() {
  ppid="$( pgrep 'i3bar' )"  # The PID of the bar, the parent for the sleep
  sleep_pid="$( pstree "${ppid}" -p | sed -n 's/.*sleep(\([0-9]*\)).*/\1/p' )"
  if [ -n "${sleep_pid}" ]; then
    kill "${sleep_pid}"
  else
    #trap "notify.sh yo" SIGSTOP
    printf '{"version":1}'  # tell i3bar to use JSON
    printf '['   # Begin the endless array
    printf '[]'  # Send empty to make loop simpler

    while :; do  # Send blocks of information forever
      printf %s ',[{"name":"time","full_text":"'"$( status )"'"}]'
      sleep "${sleep_timer}"&
      wait
    done
  fi
}

status() {
  delimiter=' | '
  {
    printf 'A:'
    amixer get Master | sed -n '/[0-9]*%/ {
      s/.*\[\([0-9]*%\)].*\[/\1 /; s/on]//; s/off]//; p
    }'

    printf %s "${delimiter}M:"
    printf %s "$( xbacklight -get | sed 's/\..*//' )"

    #awk '/^\s*w/{ print "" int($3 * 100 / 70) "%" }' /proc/net/wireless

    printf %s "${delimiter}"
    # @TODO: look into hotspot
    {
      nmcli -t -f active,ssid,signal device wifi
      nmcli -t -f active,name        connection show
    } | awk -v FS=':' '
      /^yes/ {
        if ($3) { printf "%s", $2 "" $3 "%"; }
        else    { printf "%s", $2 "🔌"; }
        pot = 1;
        exit 1;
      }
      END{ if (!pot) printf("%s", "Disconnected"); }
    '
    #sed 's/down//;s/up//' /sys/class/net/e*/operstate

    printf %s "${delimiter}B:"
    for x in $( cat /sys/class/power_supply/BAT?/capacity ); do
      case "$x" in
        [89][0-9]|100)  printf %s "$x " ;;
        [67][0-9])      printf %s "$x " ;;
        [45][0-9])      printf %s "$x " ;;
        [23][0-9])      printf %s "$x " ;;
        *)              printf %s "$x " ;;
      esac
      case "$x" in
        8[5-9]|9[0-4])
          [ "$( cat /sys/class/power_supply/AC/online )" = '1' ] \
            && notify.sh "$x charged" ;;
        [0-9]|1[0-9])
          [ "$( cat /sys/class/power_supply/AC/online )" = '0' ] \
            && notify.sh "$x left" ;;
      esac
    done

    printf %s "${delimiter}"

    date '+%Y-%b-%d (%a) %H:%M'
  } | tr -d '\n'
}



main "$@"
