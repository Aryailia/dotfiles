#!/bin/sh

NAME="$( basename "${0}"; printf a )"; NAME="${NAME%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${NAME}

DESCRIPTION
  A better api the calendar domain-specific language Remind by Dianne Skoll

OPTIONS
  -c, --calendar (passes to -c or -p argument)
    Do '-c +4' for four weeks
    Do '-c 4' for four months

  -d, --default
  -g, --gui
  -n, --remove-now
  -p, --at-weeks-ago [ARG]

  --
    Special argument that prevents all following arguments from being
    intepreted as options.
EOF
}

main() {
  # Flags
  TERMINAL='true'
  NOW='true'
  cal_range=''
  default_file=''
  start_time=''

  # Options processing
  args=''
  first_arg=''
  flags=''
  literal='false'
  while [ "$#" -gt 0 ]; do
    if ! "${literal}"; then
      # Split grouped single-character arguments up, and interpret '--'
      # Parsing '--' here allows "invalid option -- '-'" error later
      case "${1}"
        in --)      literal='true'; shift 1; continue
        ;; -[!-]*)  opts="$( outln "${1#-}" | sed 's/./ -&/g' )"
        ;; --?*)    opts="${1}"
        ;; *)       opts="regular" ;;  # Any non-hyphen value will do
      esac

      # Process arguments properly now
      for x in ${opts}; do case "${x}"
        in -h|--help)  show_help; exit 0

        ;; -c|--calendar)     cal_range="${2}"; shift 1
        ;; -d|--default)      default_file="${XDG_CONFIG_HOME}/remind/main.rem"
        ;; -g|--gui)          TERMINAL='false'
        ;; -n|--remove-now)   NOW='false'
        ;; -p|--at-weeks-ago) start_time="$(
            printf %s\\n "MSG [today()-7*${2}]" \
            | remind - \
            | grep '^[0-9]' \
          )"
          shift 1

        ;; -*)   flags="${flags} $( outln "${1}" | eval_escape )"
        ;; *)
          # replace
          if [ -z "${first_arg}" ]
            then first_arg="${1}"
            else args="${args} $( outln "${1}" | eval_escape )"
          fi
      esac done
    else
      args="${args} $( outln "${1}" | eval_escape )"
    fi
    shift 1
  done

  # Second-pass processing of the arguments

  # '--default' might appear before we specify first argument, so we have to
  # wait until we finish one pass before we know what to set {input} to
  if [ -n "${default_file}" ]; then
    input="${default_file}"
    [ -n "${first_arg}" ] && first_arg="$( outln "${first_arg}" | eval_escape )"
    eval "set -- ${flags} '-' ${first_arg} ${time} ${args}"
  else
    input="${first_arg}"
    eval "set -- ${flags} '-' ${time} ${args}"
  fi

  # run: % -d 2021-12-01
  #run: % -p 52 -c 10 -@ -d
  [ -r "${input}" ] || die FATAL 1 "Remind file '${input}' missing"
  dir="$( realpath "${input}"; printf a )"; dir="${dir%?a}"
  base="$( basename "${input}"; printf a )"; base="${base%?a}"
  dir="$( dirname "${dir}"; printf a )"; dir="${dir%?a}"
  cd "${dir}" || die FATAL 1 "Could enter remind dir '${dir}'"

  # -p2 => two months
  # -c+4 => next four weeks
  # -m => Monday first day
  # -b => 24-hour time
  if "${TERMINAL}"; then
    add_today_reminder "${base}" \
      | remind -m -c"${cal_range:-+4}" -b1 -@ "$@"
  else
    # -p2 => two months
    add_today_reminder "${base}" \
      | remind -m -p"${cal_range:-2}" -b1 -@ "$@" \
      | rem2ps \
      | zathura -
  fi
}

add_today_reminder() {
  if "${NOW}"; then
    current="$(
      printf %s\\n "MSG [current()]" | remind - | grep '^[0-9]'
    )"
    # TODO: add color for today
    printf %s\\n "REM ${current} SPECIAL COLOR 0 255 0 !NOW!"
  fi
  cat "${1}"
}



# Helpers
outln() { printf %s\\n "$@"; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

<&1 main "$@"
