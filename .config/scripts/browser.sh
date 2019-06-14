#!/usr/bin/env sh
# TODO: Make it so that w3m/etc. can be run from the gui

search_engines="${DOTENVIRONMENT}/websearches.csv"
bookmarks_file="${DOTENVIRONMENT}/bookmarks.csv"
clipboard="clipboard.sh"

show_help() {
  name="$(basename "$0"; printf a)"; name="${name%??}"
  <<EOF cat - >&2
SYNOPSIS
  ${name} TYPE COMMAND [OPTIONS] [ARG1]

DESCRIPTION
  Desgined as a command line interface for my bookmarks and websearch files
  which are both stored in csv format.

  (Also consider using surfraw)

TYPE
  copy       (alias: c) Copy to clipboard (via clipboard.sh)
  help       (alias: h) Display this help menu
  menu       (alias: m) Specify the browser to use via fzf, enables use of -b
  download   (alias: d) Use the default donwload method  (see linkhandler.sh)
  terminal   (alias: t) Use the default terminal browser (see linkhandler.sh)
  gui        (alias: g) Use the default gui browser (see linkhandler.sh)
  edit       (alias: e) Add 'bookmark' or 'search'. Open the csv in \${EDITOR}

COMMAND
  link       (alias: l, u, url)       Opens a link in the browser
  bookmarks  (alias: b, bm, bookmark) Select a bookmark
  search     (alias: s)               Select a search engine and enter a query

Type -h after the command for more information specific to the command
EOF
}



# Main
is_copy="false"
is_menu="false"
is_terminal="false"
is_download="false"
is_external="false"

main() {
  # Options processing
  case "$1" in
    h|help)  show_help; exit 0 ;;
    c|copy)      is_copy="true" ;;
    m|menu)      is_menu="true" ;;
    d|download)  is_download="true" ;;
    t|terminal)  is_terminal="true" ;;
    g|gui)       is_external="true" ;;
    e|edit)
      case "$2" in
        b|bm|bookmark|bookmarks)  "${EDITOR}" "${bookmarks_file}" ;;
        s|search)                 "${EDITOR}" "${search_engines}" ;;
      esac
      exit 0 ;;
    *)  show_help; exit 1 ;;
  esac

  cmd="$2"
  [ "$#" -ge 2 ] || die 1 "FATAL: You must have at least two parameters."
  shift 2
  case "${cmd}" in
    l|link|u|url)             browser "$@" ;;
    b|bm|bookmark|bookmarks)  prompt_bookmarks "$@" ;;
    s|search)                 prompt_search "$@" ;;
  esac
}

#
req() { require "$1" && puts "|$1$2|$1 $3"; }
list_browser() {
  req 'surf'                 ''           ''
  req 'w3m'                  ''           ''
  req 'elinks'               ''           ''
  req 'lynx'                 ''           ''
  req 'midori'               ''           ''
  req 'firefox'              ''           '--new-tab'
  req 'firefox_incognito'    '_incognito' '--private-window'
  req 'epiphany'             ''           '--private-instance --new-tab'
  req 'epiphany_incognito'   '_incognito' '--incognito-mode --new-tab'
  req 'clipboard.sh'         ''           '--write'
  req 'termux-open-url'      ''           ''
}

show_browser_help() {
  name="$(basename "$0"; printf a)"; name="${name%??}"
  <<EOF cat - >&2
SYNOPSIS
  ${name} TYPE browser [URL] [BROWSER]

DESCRIPTION
  Opens URL in a browser depending on TYPE.

  If TYPE is 'menu' then give an either an fzf menu of the available browsers
  as specified within this file by browser_list(). If BROWSER is specified,
  instead grep through that list of browsers.
EOF
}
browser() {
  # $1 is the url
  # $2 is the browser to use if menu mode is selected

  # Option processing
  if  [ "$1" = "-h" ]    || [ "$1" = "--help" ] \
      || [ "$2" = "-h" ] || [ "$2" = "--help" ]; then
    show_browser_help
    exit 0
  fi
  [ "$#" -gt 2 ] && { show_browser_browser; exit 1; }

  # Main
  require "${clipboard}" && "${is_copy}" "${clipboard}" -w "$1"
  "${is_download}" && linkhandler.sh -d "$1"
  "${is_terminal}" && linkhandler.sh -t "$1"
  "${is_external}" && linkhandler.sh -g "$1"
  if "${is_menu}"; then
    cmd="$(list_browser | prompt '2' 'Browser' '1' "$2")" || exit "$?"
    eval "setsid ${cmd} "$1" >/dev/null 2>&1 &"
    sleep 0.1  # TODO: It is really annoying that this is necessary
  fi
}


show_bookmarks_help() {
  name="$(basename "$0"; printf a)"; name="${name%??}"
  <<EOF cat - >&2
SYNOPSIS
  ${name} TYPE bookmarks [OPTIONS] [COMMAND]

DESCRIPTION
  An interface for my bookmarks file. Allows for easy searching via an \`fzf\`
  menu or via grep if SEARCH is specified.

COMMAND
  []
    If nothing is provided, then it allows search of both names and tags (to
    the exclusion of the urls)

  d, description, title
    Starts a through just the names/titles. Does not display the tags.

  l, link, u, url
    Starts a search through just the urls. Only displays url in menu

  t, tags
    Starts a search through just the tags. Does not display the names i.


OPTIONS
  -b, --browser SEARCH
    Greps through the available browsers for one that matches SEARCH.
    If specified the fzf menu for choosing a browser is not displayed.
    This only does something if TYPE is menu.

  -h, --help
    Displays this help menu.

  -s, --search SEARCH
    Greps through the available bookmarks for one that matches SEARCH.
    The stream content that is grepped is, as specified by select(), a
    bar '|' field seperated csv as specified by the COMMAND given.
    If specified, the fzf menu for choosing a search engine is not displayed.

EXAMPLES
  ${name} gui bookmarks tags
  ${name} terminal bookmarks description --search duck
  ${name} m b d -s 'classical chinese' -b w3m
EOF
}
prompt_bookmarks() {
  # Options processing
  cmd=""; browser=""; s="";
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help)     show_bookmarks_help; exit 0 ;;
      -b|--browser)  browser="$2"; shift 1 ;;
      -s|--search)   s="$2"; shift 1 ;;
      *)   cmd="$1";;
    esac
    shift 1
  done

  # Dependencies
  [ -r "${bookmarks_file}" ] || die 1 "FATAL: Requires '${bookmarks_file}'"

  # Main
  b="${bookmarks_file}"
  url="$(case "${cmd}" in
    t|tags)               <"${b}" prompt '2 4'   'Tags'      '..-2' "${s}" ;;
    d|description|title)  <"${b}" prompt '3 4'   'Name'      '..-2' "${s}" ;;
    l|link|u|url)         <"${b}" prompt '4'     'Link'      '..-2' "${s}" ;;
    a|all)                <"${b}" prompt '2 3 4' 'All'       '..-2' "${s}" ;;
    *)                    <"${b}" prompt '2 3 4' 'Tags/Link' '..-2' "${s}" ;;
  esac)" || exit "$?"
  browser "${url}" "${browser}"

}



show_search_help() {
  name="$(basename "$0"; printf a)"; name="${name%??}"
  <<EOF cat - >&2
USAGE
  ${name} TYPE search [OPTIONS]

DESCRIPTION
  An interface for my bookmarks file. Allows for easy searching via an \`fzf\`
  menu or via grep if SEARCH is specified.

OPTIONS
  -b, --browser SEARCH
    Greps through the available browsers for one that matches SEARCH.
    If specified the fzf menu for choosing a browser is not displayed.
    This only does something if TYPE is menu.

  -h, --help
    Displays this help menu.

  -e, --engine SEARCH
    Greps through the available search engines for one that matches SEARCH.
    If specified, the fzf menu for choosing a search engine is not displayed.

  -q, --query MESSAGE
    Enters MESSAGE as the value to the search URL and does not prompt the
    user to enter a query message.

EXAMPLES
  ${name} gui search
  ${name} copy search --engine searx
  ${name} copy search --query 'Blue ocean'
  ${name} t s --e enwikipedia -query Tokyo
  ${name} menu s --e enwikipedia -q Tokyo -b surf
EOF
}
prompt_search() {
  # Options processing
  url=""; browser=""; engine=""; query="";
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help)     show_search_help; exit 0 ;;
      -b|--browser)  browser="$2"; shift 1 ;;
      -e|--engine)   engine="$2"; shift 1 ;;
      -q|--query)    query="$2"; shift 1 ;;
    esac
    shift 1
  done

  # Dependencies
  [ -r "${search_engines}" ] || die 1 "FATAL: Requires '${search_engines}'"

  # Main
  pattern="$(<"${search_engines}" prompt '2 3' '' '1' "${engine}")" || exit "$?"
  [ -z "${query}" ] && {
    printf "${pattern}\\n" '[ inserts here  ]'
    prints "Enter query: "
    read -r query
  }

  url="$(printf "${pattern}" "${query}")"
  browser "${url}" "${browser}"
}

prompt() {
  # &0 the csv
  # $1 Columns to reconstruct the input csv (automatically adds line numbers)
  # $2 A label for the UI
  # $3 are the fields that are searchable by fzf
  # $4 Grep this in the selected input columns, if blank fzf
  match="$(<&0 select "0 $1" \
    | if [ -z "$4" ]; then
      require "fzf" || die 1 "FATAL: Requires 'fzf' for menu functionality."
      fzf --no-sort --height='99%' --layout=reverse --select-1 \
          --prompt="$2> " --delimiter='\|' --with-nth='2..' --nth="$3" \
        || die "$?" "FATAL: Exited out of $2 prompt"
    else
      grep "$4" -m 1 || die "$?" "FATAL: Could not grep '$4' not found"
    fi
  )" || exit "$?"
  puts "${match}" | sed 's/.*|//;s/^ *//;s/ *$//'
}

select() {
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



# Helpers
prints() { printf %s "$@"; }
puts() { printf %s\\n "$@"; }
die() { exitcode="$1"; shift 1; printf %s\\n "$@" >&2; exit "${exitcode}"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
require() {
  for dir in $(printf %s "${PATH}" | tr ':' '\n'); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0
  done
  return 1
}

main "$@"
