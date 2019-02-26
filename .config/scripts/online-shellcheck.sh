#!/usr/bin/env sh
  #
# TODO: Add coloring depending on warn level
# 
# sample output (all one line)
#   [{"file":"-","line":1,"endLine":1,"column":1,"endColumn":8,"level":"error",
#   "code":2148,"message":"Tips depend on target shell and yours is unknown. Add
#    a shebang.","fix":null}]



# Constants
shellcheck_url="https://www.shellcheck.net/shellcheck.php"



# Parameter
show_help() {
  name="$(basename "$0")"
  puts "SYNOPSIS"
  puts "  ${name} [OPTIONS] [FILE1] [FILE2] ..."
  puts ""
  puts "DESCRIPTION"
  puts "  Similar to cat/grep/etc., ignores STDIN if a file is specified"
  puts "  Sends either the STDIN or sends each file to the online shellcheck"
  puts "  website and prints that out."
  puts ""
  puts "OPTIONS"
  puts "  -d, --dump"
  puts "    Just prints out the JSON output of online shellcheck. Useful in"
  puts "    case 'jq' outputs an error (Especially since this does not handle"
  puts "    interpreting fixes suggested)"
  puts ""
  puts "  -h, --help"
  puts "    Display this help menu"
  puts ""
  puts "  -i, --ignore-fixes"
  puts "    Ignores fixes since this does not support them yet"
}



# Main
do_dump="false"
do_ignore="false"
do_stdin="true"
flag_silent=""

main() {
  output=""

  # Dependencies
  command -v jq >/dev/null 2>&1 || die "FATAL: Requires 'jq' to work"

  # Prune for options, also do validation checks
  if [ "$#" -gt 0 ]; then
    for arg in "$@"; do
      case "${arg}" in
        -h|--help)          show_help; exit 1;;
        -d|--dump)          do_dump="true"; flag_silent="--silent";;
        -i|--ignore-fixes)  do_ignore="true";;
        *)                  do_stdin="false"
                            [ -r "${arg}" ] || die "FATAL: Cannot read '${arg}'"
                            output="${output} $(quote "${arg}")"
      esac
    done
  else
    show_help; exit 1
  fi

  eval "set -- ${output}"

  # Execute on non-option arguments
  if ${do_stdin}; then
    file="$(<&0 cat -)"
    post_shellcheck "script=${file}" "var" "${file}"
  else
    for arg in "$@"; do
      post_shellcheck "script@${arg}" "path" "${arg}"
    done
  fi

  exit 0
}



# Helpers
die() { printf %s\\n "$@" >&2; exit 1; }
puts() { printf %s\\n "$@"; }
quote() { printf %s\\n "$1" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/" ; }

post_shellcheck() {
  data="$1"
  type="$2"
  target="$3"

  # ${flag_silent} negates --progress-bar
  curl --progress-bar --data-urlencode "${data}" \
      ${flag_silent} "${shellcheck_url}" \
    | { if ${do_ignore}
      then  <&0 jq 'map(.fix = null)'
      else  <&0 cat -
    fi; } | { if ${do_dump}
      then  <&0 jq '.'
      else  puts "${arg}"; <&0 json2tty "${type}" "${target}"
    fi; }
}


json2tty() {
  # switch should be 'path' or 'var'
  switch="$1"
  file="$2"
  if [ "${switch}" = "path" ] && [ ! -r "${file}" ]; then
    die "FATAL: '${file}' is not readable"
  fi

  jq <&0 -r '
    def arrow(f; g):
      " " * (f - 1)
        + "^"
        + "-" * (g - f - 1)
        + if (g - f) >= 2 then "^" else "" end
        + " "
    ;

    map(
      [ ([.line, .endLine, .column, .endColumn] | join(" ")),
        .level,
        if .line == .endLine then arrow(.column; .endColumn) else "" end
          + "SC" + (.code | tostring) + ": "
          + .message
          + if .fix != null then "\n" + .fix else "" end
      ] | join ("\n")
    ) | join("\n\n")
  ' | awk -v content_or_pathname="${file}" '
    BEGIN {
      pos = 0;
      '"$(if [ "${switch}" = "path" ]; then puts '
        while (getline line < content_or_pathname) {
          file[++pos] = line;
        }
      '; else puts '
        split(content_or_pathname, file, "\n");
      '; fi)"'

      # Change after getline so does not affect normal file processing
      FS="\n";
      RS="\n\n"; 
      j = 0;
    }

    (j++) { print(""); }  # Newline after first entry
    (1) {
      split($1, location, " ");
      for (i = location[1]; i <= location[2]; ++i) {
        print(file[i]);
      }
      output = $3;
      
      # Because of FS being a newline, NF is one more than it should be
      # due to the newline at the end. Note that sometimes awk needs this
      # one trailing newline to process properly
      for (i = 4; i <= NF; ++i) {
        output = output "\n" $(i);
      }
      print(output);
    }
  '
}

main "$@"
