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
  puts "  -h,help"
  puts "    Display this help menu"
}


# Helpers
die() { printf '%s\n' "$@" >&2; exit 1; }
puts() { printf '%s\n' "$@"; }

# Main
main() {
  case "$1" in
    -h|--help) show_help;;
    *)         check "$@"
  esac
}

check() {
  if [ $# -gt 0 ]; then
    for filepathname in "$@"; do
      [ -r "${filepathname}" ] || die "FATAL: '${filepathname}' does not exist"
    done

    for filepathname in "$@"; do
      puts "${filepathname}"
      curl "${shellcheck_url}" --progress-bar  \
          --data-urlencode "script=$(cat "${filepathname}")" \
        | json2tty path "${filepathname}"
    done
  else
    file="$(cat <&0 -)"
    curl "${shellcheck_url}" --progress-bar --data-urlencode "script=${file}" \
      | json2tty var "${file}"
  fi
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
