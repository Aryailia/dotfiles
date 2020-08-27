#!/usr/bin/env sh

NAME="$( basename "$0"; printf a )"; NAME="${NAME%?a}"


add_help() {
  printf %-20s%s "  --${3}" "(alias: ${2})"
  if [ "${1}" = 'short' ]; then
    outln ''
  elif [ "${1}" = 'detailed' ]; then
    shift 3
    outln ''
    for line in "$@"; do outln "   ${line}"; done
    outln ''
  else
    die DEV 1 "\`show_help ${1}\` must be either 'short' or 'detailed'"
  fi
}


show_help() {
  HELP_OPTIONS="$(
add_help "${1}" 'h' 'help' \
  "For help, more help can be found once TARGET is specified" \
  "eg. \`${NAME} --help download search\`" \
;
add_help "${1}" 'b' 'browser <ARG>' \
  "Specify the browser to use. See 'list' for <COMMAND> for the list" \
  "of available browsers" \
;
add_help "${1}" 'e' 'engine <ARG>' \
  "Specify which search engine to use" \
;
add_help "${1}" 'o' 'output' \
  "To print the command to stdout instead of running. If you want just" \
  "the link use \`${NAME} print ...\` instead." \
;
add_help "${1}" 'P' 'profile <ARG>' \
  "For specifying PROFILE to use as a profile for the browser" \
;
add_help "${1}" 'n' 'name' \
  "Search by name/description of bookmarks or search engines." \
  "Mutually exclusive with '--tags' and '--url'" \
;
add_help "${1}" 't' 'tags' \
  "Search by the tags associated with a given bookmark or search engine." \
  "Mutually exclusive with '--name' and '--url'" \
;
add_help "${1}" 'u' 'url' \
  "Search by the url of the bookmark or search engine" \
  "Mutually exclusive with '--name' and '--tags'" \
;
)"

  <<EOF cat - >&2
SYNOPSIS
  ${NAME} [<COMMAND> [<TARGET> [<LINK>]]] [<OPTIONS> [<ARG>]]

DESCRIPTION
  Desgined as a command line interface for my bookmarks and websearch files
  which are both stored in csv format. Use \`${NAME} --help\` for more
  details on what each option does.

  (Also consider using surfraw)

COMMAND
  menu       (alias: m) Specify the browser to use via fzf, enables use of -b
  download   (alias: d) Use the default donwload method (see handle.sh)
  terminal   (alias: t) Use the default terminal browser \${BROWSER_CLI}
  gui        (alias: g) Use the default gui browser \${BROWSER}
  edit       (alias: e) Add 'bookmark' or 'search'. Open the csv in \${EDITOR}
  run        (alias: r) Launches the browser with useful defaults
  list       (alias: l) List available browsers

TARGET
  link       (alias: l, u, url)       Opens a link in the browser
  bookmarks  (alias: b, bm, bookmark) Select a bookmark
  search     (alias: s)               Select a search engine and enter a query

OPTIONS
${HELP_OPTIONS}

EXAMPLES
  \$ ${NAME} --browser

EOF
}

# TODO: More examples

# TODO or maybe we do not want this option:
#  --launch         (alias: -l)
#    Only applicable for terminal browsers, if in an X session and this is set,
#    then 

BOOKMARKS="${DOTENVIRONMENT}/bookmarks.csv"
SEARCH_ENGINES="${DOTENVIRONMENT}/websearches.csv"
NEWLINE='
'

DEBUG='false'        # True to default to terminal prompting
OUTPUT='false'
PROGRAM=''           # Blank means default
INCOGNITO='false'

SEARCH_COLUMNS=''
SEARCH_PROMPT=''
PROGRAM=''           # Browser to use, blank will popup a menu
ALREADY_RUN='false'  # Minor optimisation
BROWSER_LIST=''      # List to populate
PROFILE=''

need_arg() { die FATAL 1 "Option '${1}' needs an argument"; }

# Prompt for both ${1} and ${2} if not provided
main() {
  # Handles options that need arguments
  args=''
  literal='false'
  bTags='false'
  bName='false'
  bUrl='false'
  ENGINE=''

  while [ "$#" -gt 0 ]; do
    "${literal}" || case "${1}"
      in --)  literal='true'; shift 1; continue
      ;; -h|--help)       show_help 'detailed'; exit 0
      ;; -i|--incognito)  INCOGNITO='true'

      # TODO: -o
      ;; -o|--output)  OUTPUT='true'
      ;; -p|--profile) PROFILE="${2:-$( missing "${1}" )}" || exit "$?"; shift 1
      ;; -b|--browser) PROGRAM="${2:-$( missing "${1}" )}" || exit "$?"; shift 1
      ;; -e|--engine)  ENGINE="${2:-$( missing "${1}" )}" || exit "$?"; shift 1
      ;; -t|--tags)    bTags='true'
      ;; -n|--name)    bName='true'
      ;; -u|--url)     bUrl='true'

      ;; *)   args="${args} $( outln "${1}" | eval_escape )"
    esac
    "${literal}" && args="${args} $( outln "${1}" | eval_escape )"
    shift 1
  done

  # Guarantee the order of SEARCH_PROMPT
  if ! "${bTags}" && ! "${bName}" && ! "${bUrl}"; then
    bTags='true'
    bName='true'
  fi
  "${bTags}" && SEARCH_COLUMNS="${SEARCH_COLUMNS},1"
  "${bTags}" && SEARCH_PROMPT="${SEARCH_PROMPT}/Tags"
  "${bName}" && SEARCH_COLUMNS="${SEARCH_COLUMNS},2"
  "${bName}" && SEARCH_PROMPT="${SEARCH_PROMPT}/Name"
  "${bUrl}" &&  SEARCH_COLUMNS="${SEARCH_COLUMNS},3"
  "${bUrl}" &&  SEARCH_PROMPT="${SEARCH_PROMPT}/Url"
  SEARCH_COLUMNS="${SEARCH_COLUMNS#,}"
  SEARCH_PROMPT="${SEARCH_PROMPT#/}"

  eval "set -- ${args}"

  # Use "${1}" to form "${cmd}"
  # If not a valid option, displays help
  # Using one instead of `set -- $( prompt` so we can implement '-o' option
  one="${1:-$( prompt_flexible '.*' "$( outln \
    "help     display the short help menu" \
    "list     displays the list of avialable browsers" \
    "print    <target>" \
    "download <target>" \
    "edit     <target>" \
    "terminal <target>" \
    "gui      <target>" \
    "menu     <target>" \
  )" "Enter one of the options: " )}"
  case "${one}"
    in h*)  show_help 'short'; exit 0
    ;; l*)
      outln "GUI and Terminal Browsers" "========================="
      list_browsers | sed 's/^/  /'
      outln '' "Terminal Browsers" "================="
      list_browsers 'terminal-only' | sed 's/^/  /'
      exit 0
    ;; p*)  cmd="outln"
    ;; d*)  cmd="download"; shift 1; set -- download link "$@"
    ;; e*)  cmd="edit"
    ;; m*)  cmd="open"; #PROGRAM=''  # default is already '' so superfluous
    ;; t*)  cmd="open_terminal"; PROGRAM="${PROGRAM:-"${BROWSER_CLI}"}"
    ;; g*)  cmd="open"; PROGRAM="${PROGRAM:-"${BROWSER}"}"
    ;; *)   show_help 'short'; exit 1
  esac

  ##############################################################################
  # Use "${two}", "${3}", and maybe --browser "${ENGINE}" to form "${link}"
  two="${2:-$( prompt_flexible '[lbs].*' "$(
    if [ "${cmd}" != "edit" ] && [ "${cmd}" != "outln" ]; then
      outln "links       | Opens a link"
    fi
    outln   "bookmarks   | Select a bookmark"
    outln   "search      | Select a search engine and a query"
  )" "${NAME} ${one}: " )}" || exit "$?" # exit if early menu exit

  # But special case "edit", also 
  # Set ${link}
  if [ "${cmd}" = "edit" ]; then
    # Each branch runs the command
    cmd="${EDITOR-vim}"
    case "${two}"
      in b*)  link="${BOOKMARKS}"
      ;; s*)  link="${SEARCH_ENGINES}"
      ;; *)   die FATAL 1 \
        "target '${two}' does not match b* s* (bookmarks/search)" \
        "Command: ${NAME} ${one} ${two}"
    esac
  else
    case "${two}"
      in l*)  # direct link
        link="${3:-$( prompt ".*" "Enter URL: " )}"

      ;; b*)  # from bookmarks file
        [ -r "${BOOKMARKS}" ] || die FATAL 1 'Error with bookmarks file'
        row="$( <"${BOOKMARKS}" tablify '|' \
          | pick_flexible "${SEARCH_PROMPT}" "${3}" "3.." "${SEARCH_COLUMNS}" \
          | decode )"
        link="$( sed -n "s/.*| *//;${row}p" "${BOOKMARKS}" )"

      ;; s*)  # from web searches file
        [ -r "${SEARCH_ENGINES}" ] || die FATAL 1 'Search engines file error'
        # Pass option specified by '--engine' to `pick_flexible` to validate
        row="$( <"${SEARCH_ENGINES}" tablify '|' \
          | pick_flexible "Engine" "${ENGINE}" "2.." "1" \
          | decode )"
        format="$( sed -n "s/.*| *//;${row}p" "${SEARCH_ENGINES}" )"
        search_string="${4:-"$( prompt ".*" "${format}: " )"}" || exit "$?"
        link="$( printf "${format}" "${search_string}" )"

      ;; *)   die FATAL 1 \
        "target '${two}' does not match l* b* s* (link/bookmarks/search)" \
        "Commmand: ${NAME} ${one} ${two}"
    esac
    # TODO check valid link?
    escaped_link="$( outln "${link}" | maybe_prefix_https )"
  fi
  "${cmd}" "${escaped_link}"
}

add_browser() {
  type "open_${1}" >/dev/null \
    || die 1 "FATAL: \`open_${1}\` function undefined in source"
  if [ -z "${BROWSER_LIST}" ]; then
    BROWSER_LIST="${1}"
  else
    BROWSER_LIST="${BROWSER_LIST}${NEWLINE}${1}"
  fi
}

list_browsers() {
  if ! "${ALREADY_RUN}"; then
    ALREADY_RUN='true'
    XORG_ON="$( [ -n "${DISPLAY}" ] && echo 'true' || echo 'false' )"
    if [ "${1}" = 'terminal-only' ]; then
      XORG_ON='false'
    elif [ -n "${1}" ]; then
      die DEV 1 "Only allows terminal-only" "list_browsers $*"
    fi

    # This is in order of greatest to least presidence
    "${XORG_ON}" && require 'firefox' && add_browser 'firefox'
    require 'termux-open-url' && add_browser 'termux_external'
    require 'lynx' && add_browser 'lynx'
    require 'w3m'  && add_browser 'w3m'

    # TODO: add these browsers
    # TODO: default browsers do not seem to check the browser list

    #"${XORG_ON}" && require 'epiphany' && add_browser 'epiphany'
    #"${XORG_ON}" && require 'midori'   && add_browser 'midori'
    #"${XORG_ON}" && require 'surf'     && add_browser 'surf'
  fi
  outln "${BROWSER_LIST}"
}

download() {
  if   require "curl"; then curl -L --help
  elif require "wget"; then wget --help
  else exit 1
  fi
}

edit() {
  file="${1:-"$( prompt_flexible '[bs].*' "$( outln \
    "bookmarks   | Select a bookmark" \
    "search      | Select a search engine and a query" \
  )" "File to edit" )"}"
}

open_terminal() { open "${1}" 'terminal-only'; }
open() {
  # $1: the url to operate on
  # $2: specify to filter to only terminal browsers or not
  list_browsers "${2}" >/dev/null  # Populate ${BROWSER_LIST}
  [ -z "${BROWSER_LIST}" ] && die FATAL 1 \
    "No browsers implemented/supported. " \
    "See \`${NAME} list\` for list of available browsers." \
    "$( if [ "${2}" = 'terminal-only' ]; then
      outln "Perhaps try \`${NAME} gui ..\` instead"
    fi )"

  browser="$( outln "${BROWSER_LIST}" \
    | pick_flexible "Browser" "${PROGRAM}" ".." ".." )"
  [ -z "${browser}" ] && "FATAL: Browser '${browser}' not in list" \
    "See \`${NAME} list\` for list of available browsers."
  open_"${browser}" "${1}"
}

################################################################################
# Browsers
maybe_prefix_https() {
  <&0 sed '
    /^www\./                  { s|^|https://|; }
    /^[^h.\/][^\/.]*\.[^\/.]/ { s|^|https://|; }
  '
}


print_or_launch() {
  if "${OUTPUT}"; then
    escape_all "$@"
    outln  # `escape_all` does not add trailing newline
  else
    # When running `$TERMINAL -e tmux.sh open browser.sh menu link gnu.org`
    # the command seems to not live long enough, particularly on slower
    # computers, thus we are using 'nohup' to help increase the lifespan
    # 'setsid' is to fork
    # 'exec' to remove the current instance of this shell program
    exec setsid nohup "$@" >/dev/null 2>&1
  fi
}

print_or_run() {
  if "${OUTPUT}"; then
    escape_all "$@"
    outln  # `escape_all` does not add trailing newline
  else
    "$@"
  fi
}

open_firefox() {
  args='firefox'
  "${INCOGNITO}" && args="${args} --private-window"
  [ -n "${PROFILE}" ] && args="${args} -P \"${PROFILE}\""
  "${OUTPUT}" || errln "Opening '${1}' in firefox" "Running: ${args} '${1}'"
  print_or_launch ${args} "${1}"  # Allow ${args} to expand
}

# TODO: epiphany options
open_epiphany() {
  [ -n "${PROFILE}" ] && errln "WARN: \`epiphany\` does not support profiles"

  args='epiphany'
  "${FLAG_INCOGNITO}" && args="${args} --incognito"
  "${OUTPUT}" \
    || errln "Opening '${1}' in \`epiphany\`" "Running: ${args} '${1}'"
  print_or_launch ${args} "${1}"  # Allow ${args} to expand
}

# TODO: midori profiles
open_midori() {
  [ -n "${PROFILE}" ] && errln "WARN: \`midori\` does not support profiles"
  args='midori'
  "${FLAG_INCOGNITO}" && args="${args} --private"
  "${OUTPUT}" || errln "Opening '${1}' in \`midori\`" "Running: ${args} '${1}'"
  print_or_launch ${args} "${1}"  # Allow ${args} to expand
}

# TODO: surf options
open_surf() {
  [ -n "${PROFILE}" ] && errln "WARN: \`surf\` does not support profiles"
  args='surf'
  "${FLAG_INCOGNITO}" && errln "WARN: \`surf\` does not support incognito"
  "${OUTPUT}" || errln "Opening '${1}' in \`surf\`" "Running: ${args} '${1}'"
  print_or_launch ${args} "${1}"  # Allow ${args} to expand
}

open_termux_external() {
  "${INCOGNITO}" && errln 'WARN: termux does not support incognito mode'
  [ -n "${PROFILE}" ] && errln 'WARN: termux does not support profiles'
  errln "Opening '${1}'" "Running: termux-open-url '${1}'"
  print_or_run 'termux-open-url' "${1}" &
}

open_w3m() {
  "${INCOGNITO}" && errln 'WARN: w3m does not support incognito mode'
  errln "Opening '${1}' in w3m" "Running: lynx '${1}'"
  print_or_run 'w3m' "${1}"
}

open_lynx() {
  "${INCOGNITO}" && errln 'WARN: termux does not support incognito mode'
  errln "Opening '${1}' in lynx" "Running: lynx '${1}'"
  print_or_run lynx "${1}"
}


################################################################################
# Dealing with CSV
tablify() {
  # &0 the csv
  # $1 the delimiter
  # $2 is the first line to include
  # $3 is the final line to include
  <&0 awk -v FS="${1}" -v first="${2}" -v last="${3}" '
    first != "" && first > NR { next; }
    last != "" &&  NR > last  { next; }
    /^#/ { next; }    # Comments
    /^ *$/ { next; }  # Empty lines

    { gsub(/@/, "@A"); }
    { gsub(/\\\\/, "@B"); }
    { gsub(/\\n/, "@N"); }
    # @D for delimiter
    { gsub(/\\"/, "@Q"); }

    '"${DECODE}"'
    function line_length(input,    i, len, output, temp) {
      len = split(input, temp, "\n");
      for (i = 1; i <= len; ++i)
        if (output < length(temp[i])) output = length(temp[i]);
      return output;
    }

    {
      # The proper CSV parsing
      counter = 0;
      delete entries;  # Clear since used on every line
      for (i = 1; i <= NF; ++i) {
        if (entries[counter] !~ /^ *"/ || entries[counter] ~ /^ *".*" *$/) {
          entries[++counter] = $(i);
        } else {
          entries[counter] = entries[counter] "@D" $(i);
        }
      }

      # NOTE: To enable automatic padding, must uncomment three sections
      # Trim and remap onto awk framework, calculate padding
      $0 = NR;
      for (i = 1; i <= counter; ++i) {
        ## Automatic padding part 1
        #gsub(/^ *"?/, "", entries[i]);  # Trim first
        #gsub(/"? *$/, "", entries[i]);  # Trim end
        $0 = $0 FS entries[i];          # Always add FS because $0 starts NR

        ## Find total length for padding
        ## Automatic padding part 2
        #temp = line_length(decode(entries[i], FS));
        #len[1] = length(NR);            # Final NR always the longest
        #if (len[i + 1] < temp) len[i + 1] = temp;
      }

      # Store for use in END, lines of the final output with skipping done
      output[++output_length] = $0;
    }
    { print decode($0, FS); }

    ## Automatic padding part 3
    #END {
    #  for (i = 1; i <= output_length; ++i) {
    #    counter = split(output[i], fields, FS);
    #    for (j = 1; j <= counter + 1; ++j) {
    #      if (j > 1) printf "%s", FS;
    #      printf "%s", fields[j];
    #      # TODO: adding padding not working yet for entries with @N
    #      temp = len[j] - line_length(decode(fields[j], FS));
    #      while (--temp > -1) printf " ";  # Add the padding
    #   }
    #    printf "\n";  # Finish line
    #  }
    #}
  '
}

decode() {
  <&0 awk -v FS="|" "${DECODE}"'{ print decode($0, FS); }'
}


DECODE='
  function decode(input, delimiter) {
    gsub(/@D/, delimiter, input);
    gsub(/@Q/, "\"", input);
    gsub(/@N/, "\n", input);
    gsub(/@B/, "\\", input);
    gsub(/@A/, "@", input);
    return input;
  }
'




################################################################################
#

pick_flexible() {
  if ! "${DEBUG}" && require "fzf"
    then <&0 pick_fzf "${1}" "${2}" "${3}" "${4}"
    else pick "${1}" "$( outln "${2}" "${3}" )" ""
  fi
}

pick_fzf() {
  # &0 the parsed csv
  # $1 A label for the UI
  # $2 select this via first option grep'd
  # $3 are the fields that visible
  # $4 are the fields that are searchable by fzf
  _match="$(
    if [ -z "${2}" ]; then <&0 fzf --no-sort --reverse --delimiter='\|' \
      --select-1 --prompt="${1}> " --with-nth="${3}" --nth="${4}"
    else <&0 grep -F "${2}" | sed '1q'
    fi
  )"
  outln "${_match%%|*}"
}

# TODO: Interactive picker with terminal values....
pick() {
  die WIP 1 "Interactive terminal picker not implemented"
}


prompt_flexible() {
  # $1: acceptable characters for terminal `prompt`
  # $2: option to choose from
  # $3: the prompt
  if ! "${DEBUG}" && require "fzf"
    then prompt_fzf "${3}" "${2}"
    else prompt "${1}" "$( outln "${2}" "${1}" )" ""
  fi
}
prompt_fzf() {
  outln "${2}" \
    | fzf --height="99%" --reverse --prompt="${1}" --nth='1' --delimiter='|' \
    | sed 's/ *|.*$//'
}




# Helpers
out() { printf %s "$@"; }
outln() { printf %s\\n "$@"; }
errln() { printf %s\\n "$@" >&2; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }

eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
escape_all() {
  out "$( outln "${1}" | eval_escape )"
  shift 1
  for a in "$@"; do
    out " $( outln "$a" | eval_escape )"
  done
}
require() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0
  done
  return 1
}

pc() { printf %b "$@" >/dev/tty; }
prompt() (
  pc "${2}"; read -r _v; pc "${CLEAR}"
  while outln "${_v}" | grep -qve "$1"; do
    pc "${3:-"$2"}"; read -r _v
    pc "${CLEAR}"
  done
  printf %s "${_v}"
)

main "$@"
