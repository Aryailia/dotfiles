#!/usr/bin/env sh

name="$( basename "$0"; printf a )"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
NAME
  ${name} - Locate relative/absolute paths and URLs in a document

SYNOPSIS
  ${name} [OPTIONS] [FILE1 [FILE2 [FILE3 ...]]]

DESCRIPTION
  Searches STDIN and/or a the file(s) specified for links or paths to any
  existing file or directory relative to the containing file's path. By default
  this outputs whatever is detected first

  The general scan has three type of scans:
    - words (separated by spaces and newlines) are tested for being valid paths
    - the content of single quotes are tested for being valid paths
    - words (separated by spaces and newlines) are tested for being valid urls
    - (considering adding double quote)

  The general scan will match less URLs than the URL-specific scan for
  useability (eg. 'hello.sh' is a valid url, but I would rather that not be
  included). Neither scan matches spaces or newlines in URLs (tabs do work
  however, perhaps that is not desired behaviour).

  The indexes given follow for the most part how Vim does it, that is the 1-row
  is the very first row of the text document, the 1-col is the very first
  column of the text document. However it differs in that, 0 will be given
  if the newline is to be included (subject to change to be the same as vim)
  index follows vim.

  The output is in the format of '<row1> <col1>|<row2> <col2>|<text>'
  Note that '<text>' could be multiple lines (if it

OPTIONS
  --
    Special argument that prevents all following arguments from being
    intepreted as options.

  -
    Special option that tells this command to read from STDIN. Also different
    from most GNU utils in that you can read from files *and* STDIN with this
    option. If you need to read a file named '-',  then use the '--' option.

  -a, --all-tests
    Scan for both paths and files. This is the default

  -l, --link-test
    Just scan for links. This implies '-n' (lax urls).

  -p, --partial-search
    Stops at the first link or path found. This is the default.

  -f, --full-search
    Run through the entire file.

  -m, --menu
    Cuts out the last and gives an fzf menu. This implies '-f'

  -n, --nonstrict-urls
    Matches any url as defined by the IEEE.

  -s, --stricter-urls
    Imposes a few extra requirements, that seem more like links. This is the
    default.

  -c, --start-col
    The column to start the search at. The default is set to 1.

  -r, --start-row
    The row to start the search at. The default is 1.

  -h, --help
    Show this help menu
EOF
}

# TODO: make the output unique, like actual csv
# TODO: support disabling quotes?
# TODO: figure out how to implement stricter urls


# Some of the globas

ENUM_DEFAULT='1'
ENUM_FIRST_FOUND='2'
ENUM_ENTIRE_FILE='3'
SCAN="${ENUM_DEFAULT}"  # Default is ENUM_FIRST_FOUND

ENUM_ALL_TESTS='1'
ENUM_URL_TEST='2'
FILTERFOR="${ENUM_ALL_TESTS}"

ENUM_STDOUT='1'
ENUM_MENU='2'
OUTPUT="${ENUM_STDOUT}"

ENUM_LAX='2'
ENUM_STRICT='3'
STRICTER_URLS="${ENUM_DEFAULT}"
FLAG_STDIN='false'
START_COL='1'
START_ROW='1'

# TODO: Make the output into proper csv
# TODO: csv filter instead of cut?

# Handles single character-options joining (eg. pacman -Syu)
main() {
  # Options processing
  args=''
  no_options='false'
  while [ "$#" -gt 0 ]; do
    if ! "${no_options}"; then
      # Split grouped single-character arguments up, and interpret '--'
      # Parsing '--' here allows "invalid option -- '-'" error later
      opts=''
      case "$1" in
        --)      no_options='true'; shift 1; continue ;;
        -[!-]*)  opts="${opts}$( puts "${1#-}" | sed 's/./ -&/g' )" ;;
        -)       FLAG_STDIN='true' ;;
        *)       opts="${opts} $1" ;;
      esac

      # Process arguments properly now
      for x in ${opts}; do case "${x}" in
        -h|--help)   show_help; exit 0 ;;
        -a|--all-tests)       FILTERFOR="${ENUM_ALL_TESTS}" ;;
        -l|--link-test)       FILTERFOR="${ENUM_URL_TEST}"
          [ "${STRICTER_URLS}" = "${ENUM_DEFAULT}" ] \
            && STRICTER_URLS="${ENUM_LAX}" ;;
        -p|--partial-search)  SCAN="${ENUM_FIRST_FOUND}" ;;
        -f|--full-search)     SCAN="${ENUM_ENTIRE_FILE}" ;;
        -m|--menu)            OUTPUT="${ENUM_MENU}"
          [ "${SCAN}" = "${ENUM_DEFAULT}" ] && SCAN="${ENUM_ENTIRE_FILE}" ;;
        -n|--nonstrict-urls)   STRICTER_URLS="${ENUM_LAX}" ;;
        -s|--stricter-urls)    STRICTER_URLS="${ENUM_STRICT}" ;;
        -c|--start-col)  START_COL="${2}"; shift 1 ;;
        -r|--start-row)  START_ROW="${2}"; shift 1 ;;

        # Put argument checks above this line (for error detection)
        # first '--' case already covered by first case statement
        -[!-]*)   show_help; die 1 "FATAL: invalid option '${x#-}'" ;;
        *)        args="${args} $( puts "$1" | eval_escape )" ;;
      esac done
    else
      args="${args} $( puts "$1" | eval_escape )"
    fi
    shift 1
  done

  eval "set -- ${args}"

  {
    if [ "$#" = '0' ] || "${FLAG_STDIN}"; then <&0 filter | run_scan "${0}"; fi
    for path in "${@}"; do <"${path}" filter | run_scan "${path}"; done
  } | defilter \
  | {
    case "${OUTPUT}" in
      "${ENUM_MENU}")    <&0 cut -d '|' -f 3 | fzf ;;
      "${ENUM_STDOUT}")  <&0 cat - ;;
    esac
  }
}

filter() {
  <&0 awk -v FS='' -v row="${START_ROW}" -v col="${START_COL}"  '
    (NR >= row) {
      print (NR == row) ? substr($0, col) : $0;
    }
  '
}

run_scan() {
  dir="$( dirname "${0}"; printf a )"; dir="${dir%?a}"
  cd "${dir}" || die 1 'FATAL' "\"${dir}\" does not exist"
  case "${FILTERFOR}" in
    "${ENUM_ALL_TESTS}")  <&0 simulate_awk ;;
    "${ENUM_URL_TEST}")   <&0 extract_url ;;
  esac
}

defilter() {
  <&0 awk -v row="${START_ROW}" -v col="${START_COL}" -v FS=' |\\|' '
    { if ($1 == 1)  $2 += col - 1; }
    { if ($3 == 1)  $4 += col - 1; }
    { $1 += row - 1; }
    { $3 += row - 1; }
    { printf("%s %s|%s %s|%s\n", $1, $2, $3, $4, $5); }
  '
}


################################################################################
# Simulating awk because `[ -e ]` test is much faster within shellscript
# Subfunctions necessary to reimplement do-while
# Prepending ?_ to variable names just to make sure no namespace collisions
simulate_awk() {
  a_line_count='0'
  while IFS= read -r a_record; do
    a_line_count="$(( a_line_count + 1 ))"
    process_line "${a_record}" "${a_line_count}" "${NEWLINE}"
  done
  process_line "${a_record}" "$(( a_line_count + 1 ))" ''  # EOF is blank
}

process_line() {
  l_queue="${1}"
  l_line_count="${2}"
  l_ender="${3}"
  while [ "${l_queue#* *}" != "${l_queue}" ]; do
    process_word "${l_line_count}" "${1}" "${l_queue}" "${l_queue%% *}" ' '
    l_queue="${l_queue#* }"
  done
  process_word "${l_line_count}" "${1}" "${l_queue}" "${l_queue}" "${l_ender}"
}

process_word() {
  # ${1} is the row number
  # ${2} is the entire line string
  # ${3} is a string of the of line remaining
  # ${4} is the word
  # ${5} is field separator, can be newline, space or nothing (no tab)
  if [ "${SCAN}" = "${ENUM_ENTIRE_FILE}" ]; then
    scan_filename    "${1}" "${2}" "${3}" "${4}"
    scan_url         "${1}" "${2}" "${3}" "${4}"
    scan_singlequote "${1}" "${2}" "${3}" "${4}${5}"
  else
    scan_filename    "${1}" "${2}" "${3}" "${4}" \
      || scan_url         "${1}" "${2}" "${3}" "${4}" \
      || scan_singlequote "${1}" "${2}" "${3}" "${4}${5}" \
      && exit 0
  fi
}



################################################################################
# The different scans
scan_filename() {
  if [ -e "${4}" ]; then
    [ -n "${2}" ] && [ -n "${3}" ] && [ "${2%"${3}"}" = "${2}" ] \
      && die 2 'DEV' "line arg (\${2}) does not contain rest arg (\${3})" \
        "row ${1}" "|${2}|" "|${3}|"
    f_firstline="$( puts "${4}" | sed 1q )"  # only for error checking
    [ -n "${f_firstline}" ] && [ "${3#"${f_firstline}"}" = "${3}" ] \
      && die 2 'DEV' "rest arg (\${3}) does not contain word arg first line" \
        "row $1" "|${f_firstline}|" "|${3}|" "|${4}|" "|${3#"${f_firstline}"}|"

    f_line="$( puts "${2}" | sed 's|\\|\\\\|g'; printf a )"
    f_rest="$( puts "${3}" | sed 's|\\|\\\\|g'; printf a )"
    f_line="${f_line%?a}"; f_rest="${f_rest%?a}"

    printf %s\\n "${4}" | awk -v row="${1}" \
      -v line="${f_line}" -v rest="${f_rest}" \
    '
      { len = length($0); }
      END {
        startcol = length(line) - length(rest) + 1;
        endrow   = row + NR - 1;
        printf("%s %s|", row, startcol);
        # If there were multiple lines, only need last length() value
        printf("%s %s|", endrow, (endrow == row) ? startcol + len - 1 : len);
      }
    '
    printf %s\\n "${4}"
  else
    return 1
  fi
}



# A string of only-question marks, an efficient way to length test in POSIX
LENGTH_TEST=''
c='0'  # Throwaway ${c}
while [ "${c}" -lt 255 ]; do  # 255 is limit for file paths (not path strings)
  c="$(( c + 1 ))"
  LENGTH_TEST="${LENGTH_TEST}?"
done
SQ_ROW=''
SQ_LINE=''
SQ_REST=''
SQ_BUFFER=''
NEWLINE='
'
scan_singlequote() {
  sq_word="${4}"
  sq_return='1'
  # Decide how to add to buffer
  if [ -z "${SQ_BUFFER}" ] && [ "${sq_word##*\'*}" != "${sq_word}" ]; then
    SQ_ROW="${1}"       # Only remember when quote begins
    SQ_LINE="${2}"      # Only remember when quote begins
    SQ_REST="${3#*\'}"  # Only remember when quote begins
    SQ_BUFFER="${sq_word#*\'}"  # without the starting quote
    #if [ "${SQ_BUFFER#*\'}" != "${SQ_BUFFER}" ]; then
    #  puts "-----" "${sq_word}"
    #fi
  elif [ -n "${SQ_BUFFER}" ]; then  # Build up the quote
    SQ_BUFFER="${SQ_BUFFER}${sq_word}"
  fi

  # Detect for closing quote, cannot be certain of correct parsing, so check all
  # eg. "a'" checks for "a"; "a''b'c'" check "a" "b" "" and "c"
  while [ "${SQ_BUFFER#*\'}" != "${SQ_BUFFER}" ]; do  # Not empty & has quote
    scan_filename "${SQ_ROW}" "${SQ_LINE}" "${SQ_REST}" "${SQ_BUFFER%%\'*}" \
      && sq_return='0'  # return true if even one thing is found

    # Only possible to be true on the first pass of the loop
    # Could optimise this out by expanding loop
    if [ "${SQ_ROW}" != "${1}" ]; then
      SQ_ROW="${1}"
      SQ_LINE="${2}"
      SQ_REST="${3}"
    fi
    SQ_BUFFER="${SQ_BUFFER#*\'}"
    SQ_REST="${SQ_REST#*\'}"
  done

  # If length of ${SQ_BUFFER} >= ${LENGTH_TEST}
  [ "${SQ_BUFFER#${LENGTH_TEST}}" != "${SQ_BUFFER}" ] && SQ_BUFFER=''
  return "${sq_return}"
}

scan_url() {
  # Initial check with shell to avoid invoking externals in `extracl_url`
  if   [ "${STRICTER_URLS}" = "${ENUM_DEFAULT}" ] \
    || [ "${STRICTER_URLS}" = "${ENUM_LAX}" ]
  then
    case "${4}" in
      [!/.]*.[!/.]*) ;;
      *) return 1 ;;
    esac
  else
    # Check `extract_url` as well for stricter checks
    case "${4}" in
      # NOTE: This are greater requirements than URLs normally have
      # A url can just be 'hello.sh' but for usability, do not want that matched
      *[!/.]*.[!/.]*.[!/.]*)  ;;  # two periods
      *[!/.]*.[!/.]*/?*)  ;;       # one periods with a slash
      *https://[!/.]*)  ;;
      *[!/.]*.com*)  ;;
      *[!/.]*.org*)  ;;
      *[!/.]*.io*)  ;;
      *[!/.]*.gg*)  ;;
      *)  return 1 ;;
    esac
  fi

  puts "${2}" | extract_url | awk -v offset="${1}" -v FS=' |\\|' '
    { $1 += offset - 1; }
    { $3 += offset - 1; }
    { printf("%s %s|%s %s|%s\n", $1, $2, $3, $4, $5); }
  '
}



################################################################################
# URL Handler
extract_url() {
  # can use --posix flag for testing
  <&0 awk --posix '
    BEGIN {
      # If we want to do specific schemes
      #scheme = "("
      #scheme = scheme "https?|s?ftp|udp|mailto|magnet|file|irc|data|ssh"
      #scheme = scheme "|gopher|mid|cid|news|nntp|prospero|telnet|wais"
      #scheme = scheme ")?"

      scheme = "[a-z]+"
      userinfo = "([A-Za-z0-9_.:]+@)"  # TODO: password (deprecated)
      port = "[0-9]{1,5}"
      host_character = "[-a-zA-Z0-9%_]"
      path_character = "[-a-zA-Z0-9%_:=+.~#=@?&/!;,]"

      regexp=""
      regexp = regexp "(" scheme "://" userinfo "?)?"
      regexp = regexp "" host_character "+(\\." host_character "+)+"
      regexp = regexp "(:" port ")?"
      regexp = regexp "(/" path_character "*)?"

      anyfound = 0;
    }
    ("'"${SCAN}"'" == "'"${ENUM_ENTIRE_FILE}"'" || !anyfound) {
      pos = match($0, regexp);
      str = substr($0, RSTART, RLENGTH);
      if (pos > 0) {
        if ("'"${STRICTER_URLS}"'" == "'"${ENUM_DEFAULT}"'" ||
            "'"${STRICTER_URLS}"'" == "'"${ENUM_LAX}"'" ||
            str ~ /[!.\/]+\.[!.\/]+\.[!.\/]+/ || str ~ /[!.\/]+\.[!.\/]+\/./ ||
            str ~ /https:\/\/.+\..+/ || str ~ /.+\.(com|org|io|gg)/)
        {
          anyfound = 1;
          printf("%s %s|", NR, RSTART);
          printf("%s %s|", NR, RSTART + RLENGTH - 1);
          printf("%s\n", str);
        }
      }
    }
    END {
      exit (anyfound) ? 0 : 1;
    }
  '
}



# Helpers
puts() { printf %s\\n "$@"; }
prints() { printf %s "$@"; }
puterr() { printf %s\\n "$@" >&2; }
die() { c="$1"; puterr "$2: '${name}' -- $3"; shift 3; puterr "$@"; exit "$c"; }

eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

main "$@"
