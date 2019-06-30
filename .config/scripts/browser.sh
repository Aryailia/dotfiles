#!/usr/bin/env sh
# TODO: add warning for profile
# TODO: add warning for --browser without 'menu' specified

name="$( basename "$0"; printf a )"; name="${name%?a}"
search_engines="${DOTENVIRONMENT}/websearches.csv"
bookmarks_file="${DOTENVIRONMENT}/bookmarks.csv"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name} <COMMAND> <TARGET> [<OPTIONS>] [<ARG1>, [<ARG2>, [...]]]

DESCRIPTION
  Desgined as a command line interface for my bookmarks and websearch files
  which are both stored in csv format.

  (Also consider using surfraw)

COMMAND
  menu       (alias: m) Specify the browser to use via fzf, enables use of -b
  download   (alias: d) Use the default donwload method  (see linkhandler.sh)
  terminal   (alias: t) Use the default terminal browser (see linkhandler.sh)
  gui        (alias: g) Use the default gui browser (see linkhandler.sh)
  edit       (alias: e) Add 'bookmark' or 'search'. Open the csv in \${EDITOR}
  run        (alias: r) Launches the browser with useful defaults
  list       (alias: l) List available browsers

TARGET
  link       (alias: l, u, url)       Opens a link in the browser
  bookmarks  (alias: b, bm, bookmark) Select a bookmark
  search     (alias: s)               Select a search engine and enter a query

$( help_universal_options )
EOF
}

help_universal_options() {
  # Not to STDERR because this is meant to be included within other things
  <<EOF cat
UNIVERSAL OPTIONS
  --help           (alias: -h)
    For help, more help can be found once TARGET is specified
    eg. \`${name} --help download search\`

  --launch         (alias: -l)
    Only applicable for terminal browsers, if in an X session and this is set,
    then 

  --output         (alias: -o, -p)
    To print the command to stdout

  --profile <ARG>  (alias: -P)
    For specifying PROFILE to use as a profile for the browser
EOF
}



# Main
COMMAND='0'
ENUM_DOWNLOAD='1'
ENUM_TERMINAL='2'
ENUM_GUI='3'
ENUM_MENU='4'
ENUM_EDIT='5'

FLAG_NO_OPTIONS='false'
FLAG_HELP='false'
FLAG_PRINT='false'
FLAG_INCOGNITO='false'
FLAG_LAUNCH='false'
PROFILE=''

main() {
  # Options processing
  args=''
  while [ "$#" -gt 0 ]; do
    "${FLAG_NO_OPTIONS}" || case "$1" in
      --)  FLAG_NO_OPTIONS='true'; shift 1; continue ;;
      -h|--help)       FLAG_HELP='true' ;;
      -o|-p|--print)   FLAG_PRINT='true' ;;
      -i|--incognito)  FLAG_INCOGNITO='true' ;;
      -l|--launch)     FLAG_LAUNCH='true' ;;
      -P|--profile)    PROFILE="$2"; shift 1 ;;
      *)   args="${args} $( puts "$1" | eval_escape )" ;;
    esac
    "${FLAG_NO_OPTIONS}" && args="${args} $( puts "$1" | eval_escape )"
    shift 1
  done

  [ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"

  # Command processing
  cmd="$1"; [ "$#" -gt 0 ] && shift 1
  target="$1"; [ "$#" -gt 0 ] && shift 1
  case "${cmd}" in
    d|download)  COMMAND="${ENUM_DOWNLOAD}" ;;
    g|gui)       COMMAND="${ENUM_GUI}" ;;
    m|menu)      COMMAND="${ENUM_MENU}" ;;
    t|terminal)  COMMAND="${ENUM_TERMINAL}" ;;
    e|edit)      require "${EDITOR}" || die2 1 'FATAL' "problem with \${EDITOR}"
                 COMMAND="${ENUM_EDIT}" ;;
    r|run)       launch_browser "${target}" "$@"; exit 0 ;;
    l|list)      list_browsers; exit 0 ;;
    #    b|bm|bookmark|bookmarks)  "${EDITOR}" "${bookmarks_file}" ;;
    #    s|search)                 "${EDITOR}" "${search_engines}" ;;
    *)  show_help; exit 1 ;;
  esac

  # Process target
  case "${target}" in
    l|link|u|url)             process_link "$@" ;;
    b|bm|bookmark|bookmarks)  process_bookmarks "$@" ;;
    s|search)                 process_search "$@" ;;
    *)  die2 1 'FATAL' "'${target}' is not a valid target, use -h for help" ;;
  esac
}


list_browsers() { puts "${browser_list}"; }
launch_browser() {
  if "${FLAG_HELP}"; then
    pute "Usage: ${name} run <BROWSER> [<URL>]" \
      "  Open browser with my default settings" \
      "" \
      "Choose from:"
    list_browsers | sed 's/^/  /' >&2
    exit 0
  else
    browser="$1"; shift 1
    type "_run_${browser}" >/dev/null >&1 || die2 1 'FATAL' "invalid browser"
    _run_"${browser}" "$@"
  fi
}



show_link_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name} <COMMMAND> browser [<URL>] [<BROWSER>]

DESCRIPTION
  Opens URL in a browser, choosen depending on COMMAND.

  If TYPE is 'menu' then give an either an fzf menu of the available browsers
  as specified within this file by \`browser_list\`. If BROWSER is specified,
  instead grep through that list of browsers.

$( help_universal_options )

OPTIONS
  --browser <ARG>  (alias: -b)
    If specified, greps the supported browsers
EOF
}
process_link() {
  "${FLAG_HELP}" && { show_link_help; exit 1; }

  # Options processing
  args=''; browser=''; # "${FLAG_OPTIONS}" initialised by main()
  while [ "$#" -gt 0 ]; do
    "${FLAG_NO_OPTIONS}" || case "$1" in
      --)  FLAG_NO_OPTIONS='true'; shift 1; continue ;;
      -b|--browser)  browser="$2"; shift 1 ;;
      *)   args="${args} $( puts "$1" | eval_escape )" ;;
    esac
    "${FLAG_NO_OPTIONS}" && args="${args} $( puts "$1" | eval_escape )"
    shift 1
  done
  eval "set -- ${args}"

  # Main
  case "${COMMAND}" in "${ENUM_DOWNLOAD}"|"${ENUM_TERMINAL}"|"${ENUM_GUI}")
    require 'linkhandler.sh' || die2 1 'FATAL' "Require 'linkhandler.sh'" ;;
  esac

  url="$(if [ "$#" -gt 0 ] && [ -n "$1" ]
    then prints "$1"
    else terminal_prompt "Enter url: "
  fi | prepend_https)"

  case "${COMMAND}" in
    "${ENUM_DOWNLOAD}") linkhandler.sh -d "${url}" ;;
    "${ENUM_TERMINAL}") linkhandler.sh -t "${url}" ;;
    "${ENUM_GUI}")      linkhandler.sh -g "${url}" ;;
    "${ENUM_EDIT}")     "${EDITOR}" "$0" ;;
    "${ENUM_MENU}")
      choice="$( list_browsers | prompt '1' 'Browser' '1' "${browser}" )" \
        || exit "$?"
      launch_browser "${choice}" "${url}"
      ;;
    *)  die 1 'DEV' "\`process_link\` - Should be caught by \`main\`" ;;
  esac
}


show_bookmarks_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name} <COMMAND> bookmarks [<OPTIONS>] [<CATEGORY>]

DESCRIPTION
  An interface for my bookmarks file. Allows for easy searching via an \`fzf\`
  menu or via grep if SEARCH is specified.

CATEGORY
  <blank>
    If nothing is provided, then it allows search of both names and tags (to
    the exclusion of the urls)

  d, description, title
    Starts a through just the names/titles. Does not display the tags.

  l, link, u, url
    Starts a search through just the urls. Only displays url in menu

  t, tags
    Starts a search through just the tags. Does not display the names i.


OPTIONS
  --browser <ARG>  (alias: -b)
    Greps through the available browsers for one that matches ARG.
    If specified the fzf menu for choosing a browser is not displayed.
    This only does something if TYPE is menu.

  --search <ARG>   (alias: -s)
    Greps through the available bookmarks for one that matches ARG.
    The stream content that is grepped is, as specified by select(), a
    bar '|' field seperated csv as specified by the COMMAND given.
    If specified, the fzf menu for choosing a search engine is not displayed.

$( help_universal_options )

EXAMPLES
  ${name} gui bookmarks tags
  ${name} terminal bookmarks description --search duck
  ${name} m b d -s 'classical chinese' -b w3m
EOF
}
process_bookmarks() {
  # Dependencies
  [ -r "${bookmarks_file}" ] || die2 1 'FATAL' "Requires '${bookmarks_file}'"

  # Other branches
  [ "${COMMAND}" = "${ENUM_EDIT}" ] \
    && { "${EDITOR}" "${bookmarks_file}"; exit 0; }
  "${FLAG_HELP}" && { show_link_help; exit 1; }

  # Options processing
  args=''; browser=''; s=''; # ${FLAG_OPTIONS} init in `main`
  while [ "$#" -gt 0 ]; do
    "${FLAG_NO_OPTIONS}" || case "$1" in
      --)  FLAG_NO_OPTIONS='true'; shift 1; continue ;;
      -b|--browser)  browser="$2"; shift 1 ;;
      -s|--search)   s="$2"; shift 1 ;;
      *)   args="${args} $( puts "$1" | eval_escape )" ;;
    esac
    "${FLAG_NO_OPTIONS}" && args="${args} $( puts "$1" | eval_escape )"
    shift 1
  done
  eval "set -- ${args}"

  # Main
  url="$(cat "${bookmarks_file}" |
    case "$1" in
      t|tags)               prompt '2 4'   'Tags'      '..-2' "$s" ;;
      d|description|title)  prompt '3 4'   'Name'      '..-2' "$s" ;;
      l|link|u|url)         prompt '4'     'Link'      '..-2' "$s" ;;
      a|all)                prompt '2 3 4' 'All'       '..-2' "$s" ;;
      *)                    prompt '2 3 4' 'Tags/Link' '..-2' "$s" ;;
    esac
  )" || exit "$?"
  process_link --browser "${browser}" "${url}"
}



show_search_help() {
  <<EOF cat - >&2
USAGE
  ${name} COMMAND search [OPTIONS]

DESCRIPTION
  An interface for my bookmarks file. Allows for easy searching via an \`fzf\`
  menu or via grep if SEARCH is specified.

OPTIONS
  -b, --browser SEARCH
    Greps through the available browsers for one that matches SEARCH.
    If specified the fzf menu for choosing a browser is not displayed.
    This only does something if TYPE is menu.

  -e, --engine SEARCH
    Greps through the available search engines for one that matches SEARCH.
    If specified, the fzf menu for choosing a search engine is not displayed.

  -q, --query MESSAGE
    Enters MESSAGE as the value to the search URL and does not prompt the
    user to enter a query message.

EXAMPLES
  ${name} gui search
  ${name} menu search --engine searx
  ${name} terminal search --query 'Blue ocean'
  ${name} t s --e enwikipedia --query Tokyo
  ${name} menu s --e enwikipedia -q Tokyo -b surf
EOF
}
process_search() {
  # Dependencies
  [ -r "${search_engines}" ] || die2 1 'FATAL' "Requires '${search_engines}'"

  # Other branches
  [ "${COMMAND}" = "${ENUM_EDIT}" ] \
    && { "${EDITOR}" "${search_engines}"; exit 0; }
  "${FLAG_HELP}" && { show_link_help; exit 1; }

  # Options processing
  url=''; browser=''; engine=''; query=''; # ${FLAG_OPTIONS} init in `main`
  while [ "$#" -gt 0 ]; do
    "${FLAG_NO_OPTIONS}" || case "$1" in
      --)  FLAG_NO_OPTIONS='true'; shift 1; continue ;;
      -h|--help)     show_search_help; exit 0 ;;
      -b|--browser)  browser="$2"; shift 1 ;;
      -e|--engine)   engine="$2"; shift 1 ;;
      -q|--query)    query="$2"; shift 1 ;;
      *)   args="${args} $( puts "$1" | eval_escape )" ;;
    esac
    "${FLAG_NO_OPTIONS}" && args="${args} $( puts "$1" | eval_escape )"
    shift 1
  done
  eval "set -- ${args}"

  # Main
  form="$( <"${search_engines}" prompt '2 3' '' '1' "${engine}" )" || exit "$?"
  [ -z "${query}" ] && {
    printf "${form}\\n" '[ inserts here  ]'
    query="$( terminal_prompt "Enter query: " )"
  }

  url="$( printf "${form}" "${query}" )"
  process_link --browser "${browser}" "${url}"
}


################################################################################
# Prompting
terminal_prompt() (
  printf %s "$1" >/dev/tty
  read -r input
  printf %s "${input}"
)

prompt() {
  # &0 the csv
  # $1 columns of csv to select (eg. '1 4' selects (1st auto-added) 2nd 5th)
  # $2 A label for the UI
  # $3 are the fields that are searchable by fzf
  # $4 select this via first option grep'd
  match="$(<&0 csv_select_columns "0 $1" \
    | if [ -z "$4" ]
      then
        require "fzf" || die2 1 'FATAL' "Requires 'fzf' for menu functionality."
        fzf --no-sort --height='99%' --layout=reverse --select-1 \
            --prompt="$2> " --delimiter='\|' --with-nth='2..' --nth="$3" \
          || die2 "$?" 'FATAL' "Exited out of $2 prompt"

      # Max one
      else grep "$4" -m 1 || die2 "$?" 'FATAL' "'$4' not found"
    fi
  )" || exit "$?"  # Stop here before sed'ing in case of any error

  # Remove column number added by `csv_select_columns` after fzf/grep has
  # used the column number to select. Also remove leading/trailing spaces
  puts "${match}" | sed 's/.*|//;s/^ *//;s/ *$//'
}

# Select the columns to use of a csv separated by '|'
# This auto adds column number so that duplicates can be selected by prompt
csv_select_columns() {
  <&0 awk -v FS="|" -v select="$*" '
    BEGIN { split(select, cols, " "); count = length(cols); }
    /^ *\/\/|^ *$/ { next; }       # ignore commments, blank lines
    (1) {
      tmp = "";
      for (i = 1; i <= count; ++i) {
        if (cols[i] == 0) {
          tmp = tmp FS NR
        } else {
          #gsub(/^[ \t\f\r\n]*|[ \t\f\r\n]*$/, "", $(cols[i]));
          tmp = tmp FS $(cols[i]);
        }
      }
      print(substr(tmp, 2));  # skip the extra FS as the first character
    }
  '
}

# NOTE: Currently not being used
# In case we do not want to rely on the files being padded by themselves
# Removes comments and and pads columns to have the same width (or at least
# that is what it is suppose to do)
# Does not seem to link unicode for padding
pad() {
  awk -v FS='\|' -e '
    /^ *\/\// { next; }
    FNR == NR {
      for (i = 1; i < NF; ++i) {
        if (length($(i)) > size[i]) size[i] = length($(i));
      }
    }
    NR > FNR  {
      line=""
      for (i = 1; i < NF; ++i) {
        gsub("^[ \f\n\r\t]*|[ \f\n\r\t]*$", "", $(i)); # strip
        line = sprintf("%s%s%-" size[i] "s", line, FS, $(i)); Pad
      }
      line = line FS $(NF);
      print(substr(line, 2));  # skip the extra FS as the first character
    }
  END { for (i = 1; i <= length(size); ++i) { print size[i]; }}
  ' "$1" "$1"

}


################################################################################
# Helpers
require() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0
  done
  return 1
}
prints() { printf %s "$@"; }
puts() { printf %s\\n "$@"; }
pute() { printf %s\\n "$@" >&2; }
die2() { c="$1"; pute "$2: '${name}' -- $3"; shift 3; pute "$@"; exit "$c"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
escape_all() { for a in "$@"; do printf ' '; prints "$a" | eval_escape; done; }

################################################################################
# Browsers helpers
is_xorg_on="$( if [ -n "${DISPLAY}" ]; then echo 'true'; else 'false'; fi )"
browser_list=''

add_browser() {
  case "$1" in xorg)  "${is_xorg_on}" || return 1 ;; esac
  if [ -n "${browser_list}" ]
    then browser_list="$( puts "${browser_list}" "$2" )";
    else browser_list="$2";
  fi
}
print_or_launch() {
  if "${FLAG_PRINT}"
    then prints "$1"
  else
    eval "set -- $1"
    # `exec` and `setsid` allow the launching terminal to close gracefully
    # `setsid` unlinks the I/O streams
    exec setsid "$@" >/dev/null 2>&1
  fi
  exit 0
}
print_or_eval() {
  if "${FLAG_PRINT}"; then
    printf %s "$1"
    [ "$#" -ge 1 ] && shift 1
    for arg in "$@"; do prints " $( puts "${arg}" | eval_escape )"; done
  else
    # I think in most of my use cases, eval is not actually necessary
    # but only here to appease linter
    eval "$@"
  fi
}
# For use when the program does not support adding new tabs from cli
# Use `xdotool` to switch to window, new tab (ctrl+t), and paste from clipboard
copy_paste() {
  #cmd="$1"
  pid="$( pgrep "$1" )"
  # Not sure how to make this more consistent
  if [ -n "${pid}" ] && require 'xdotool'; then
    shift 1
    if [ "$#" -gt 0 ]
      then setsid clipboard.sh --write "$@"
      else setsid clipboard.sh --write ""
    fi
    #clipboard.sh -r

    #windowId="$(xwininfo -root -tree \
    #  | grep -i "${cmd}" \
    #  | awk '/^ *0x/{ print $1; }' \
    #  | xargs sh -c 'for a in "$@"; do
    #    xprop -id "$a" WM_STATE | grep -vq "not found" && printf %s "$a"
    #  done' _
    #)"
    #xdotool key --window "${windowId}" ctrl+t ctrl+v Return Return

    exec setsid sh -c '
      for id in $(xdotool search --pid "'"${pid}"'" ); do
        if [ -z "$( xdotool windowactivate "${id}" 2>&1 )" ]; then
          # As input does not buffer, sleep in case GUI slow (eg. epiphany)
          xdotool key ctrl+t
          sleep 0.03
          xdotool key ctrl+v
          sleep 0.03
          xdotool key Return
          break
        fi
      done
    ' >/dev/null 2>&1
    return 0
  else
    return 1
  fi
}

prepend_https() {
  sed '
    /^www\./                  { s|^|https://|; }
    /^[^h.\/][^\/.]*\.[^\/.]/ { s|^|https://|; }
  '
}

# Does not join, prepends all with a space as well as the 'https' if relevant
escape_all_and_prepend_https() {
  for arg in "$@"; do
    printf ' '
    prints "${arg}" | prepend_https | eval_escape
  done
}

################################################################################
# Browsers
# Commands for running the browsers
# If a GUI browser, then handle the setsid stuff here
firefox --version >/dev/null >&1 && add_browser xorg 'firefox'
_run_firefox() {
  args='firefox'
  "${FLAG_INCOGNITO}" && args="${args} --private-window"
  [ -n "${PROFILE}" ] && args="${args} -P ${PROFILE}"
  [ -n "$*" ] && args="${args}$( escape_all "$@" )"
  print_or_launch "${args}"
}

# 'elinks'
# 'lynx'

surf -v >/dev/null 2>&1; [ "$?" = '1' ] && add_browser xorg 'surf'
_run_surf() { print_or_launch "surf" "$@"; }

epiphany --help >/dev/null 2>&1 && add_browser xorg 'epiphany'
_run_epiphany() {
  eval "copy_paste epiphany $( escape_all_and_prepend_https "$@" )" || {
    [ -n "${PROFILE}" ] && pute "WARN: \`epiphany\` does not support profiles"

    args='epiphany'
    "${FLAG_INCOGNITO}" && args="${args} --incognito"
    [ -n "$*" ] && args="${args}$( escape_all "$@" )"
    echo "${args}"
    print_or_launch "${args}"
  }
}

midori --version >/dev/null 2>&1 && add_browser xorg 'midori'
_run_midori() {
  [ -n "${PROFILE}" ] && pute "WARN: \`midori\` does not support profiles"

  args='midori'
  "${FLAG_INCOGNITO}" && args="${args} --private"
  [ -n "$*" ] && args="${args}$( escape_all_and_prepend_https "$@" )"
  print_or_launch "${args}"
}

w3m -version >/dev/null 2>&1 && add_browser both 'w3m'
_run_w3m() {
  "${FLAG_INCOGNITO}" && pute "WARN: \`w3m\` does not support incognito mode"
  [ -n "${PROFILE}" ] && pute "WARN: \`w3m\` does not support profiles"

  args="$( printf 'sh -c %sw3m "$1"; [ -f "%s" ] && rm "%s"%s _' \
    "'" "${HOME}/.w3m/cookie" "${HOME}/.w3m/cookie" "'"
  )"
  [ "$#" = 0 ] && args="${args} ."
  args="${args}$( escape_all "$@" )"
  if "${FLAG_LAUNCH}" && "${is_xorg_on}"; then
    require "${TERMINAL}" || die2 1 'FATAL' "\$TERMINAL is not set properly"
    args="$( puts "${args}" | eval_escape )"
    print_or_launch "${TERMINAL} -e tmux.sh open ${args}"
  else
    print_or_eval "${args}"
  fi
}

termux-open-url >/dev/null 2>&1 && add_browser both 'termux_external'
_run_termux_external() {
  "${FLAG_INCOGNITO}" && pute 'WARN: termux does not support incognito mode'
  [ -n "${PROFILE}" ] && pute 'WARN: termux does not support profiles'
  print_or_eval "termux-open-url$(escape_all "$@")"
}

# For copying just the link without any browser rubbish
add_browser both 'clipboard'
_run_clipboard() {
  print_or_eval "setsid clipboard.sh --write$( escape_all "$@" )"
}

################################################################################
main "$@"
