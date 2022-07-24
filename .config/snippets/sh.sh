#!/usr/bin/env sh

# TODO: read_from

#https://www.w3.org/QA/2002/04/valid-dtd-list.html

addPrefixedFunction 'sh' 'hashbang_sh' 'Shebang env for POSIX shell'
sh_hashbang_sh() { outln '#!/usr/bin/env sh'; }
addPrefixedFunction 'sh' 'hashbang_awk' 'Shebang for awk'
sh_hashbang_awk() { outln '#!/usr/bin/awk -f'; }

addPrefixedFunction 'sh' 'name' 'Basename of current script'
sh_name() { outln 'NAME="$( basename "${0}"; printf a )"; NAME="${NAME%?a}"'; }

addPrefixedFunction 'sh' 'glob' 'Glob to match normal and hidden files'
sh_glob() { out "* .[!.]* ..?*"; }

addPrefixedFunction 'sh' 'match_to' \
  'Parameter subtitution to check for containing a string and is not-empty'
sh_match_to() { out '[ "${<>}" != "${<>#*<>}" ] && <>'; }

addPrefixedFunction 'sh' 'set_preserve' 'Set and preserve newlines'
sh_set_preserve() { out '<>="$( <>; printf a )"; <>="${<>%?a}"'; }

addPrefixedFunction 'sh' 'cd_project' "Run from dir where the script resides"
sh_cd_project() {
  <<EOF cat -
WD="\$( dirname "\$0"; printf a )"; WD="\${WD%?a}"
cd "\${WD}" || { printf "Could not cd to directory of '%s'" "\$0" >&2; exit 1; }
#WD="\$( pwd -P; printf a )"; WD="\${WD%?a}"
EOF
}


addPrefixedFunction 'sh' 'fg_RED'     'Red foreground escape'
addPrefixedFunction 'sh' 'fg_GREEN'   'Green foreground escape'
addPrefixedFunction 'sh' 'fg_YELLOW'  'Yellow foreground escape'
addPrefixedFunction 'sh' 'fg_BLUE'    'Blue foreground escape'
addPrefixedFunction 'sh' 'fg_MAGENTA' 'Magenta foreground escape'
addPrefixedFunction 'sh' 'fg_CYAN'    'Cyan foreground escape'
addPrefixedFunction 'sh' 'fg_CLEAR'   'Clear foreground escape'
sh_fg_RED() {     outln "RED='\\001\\033[31m\\002'"; }
sh_fg_GREEN() {   outln "GREEN='\\001\\033[32m\\002'"; }
sh_fg_YELLOW() {  outln "YELLOW='\\001\\033[33m\\002'"; }
sh_fg_BLUE() {    outln "BLUE='\\001\\033[34m\\002'"; }
sh_fg_MAGENTA() { outln "MAGENTA='\\001\\033[35m\\002'"; }
sh_fg_CYAN() {    outln "CYAN='\\001\\033[36m\\002'"; }
sh_fg_CLEAR() {   outln "CLEAR='\\001\\033[0m\\002'"; }

################################################################################
# Helper

# `p` is for /dev/tty, the `c` in `pc` represents colour
# /dev/tty in case `pc` is run in a subshell
addPrefixedFunction 'sh' 'p'     'Print to tty'
addPrefixedFunction 'sh' 'pln'   'Print to tty with newlines'
addPrefixedFunction 'sh' 'pc'    'Print %b to tty'
addPrefixedFunction 'sh' 'pcln'  'Print %b to tty with newlines'
addPrefixedFunction 'sh' 'out'   'Print to stdout'
addPrefixedFunction 'sh' 'outln' 'Print to stdout with newlines'
addPrefixedFunction 'sh' 'err'   'Print to stderr'
addPrefixedFunction 'sh' 'errln' 'Print to stderr with newlines'
sh_p() { outln 'p() { printf %s "$@" >/dev/tty; }'; }
sh_pln() { outln 'pln() { printf %s\\n "$@" >/dev/tty; }'; }
sh_pc() { outln 'pc() { printf %b "$@" >/dev/tty; }'; }
sh_pcln() { outln 'pcln() { printf %b\\n "$@" >/dev/tty; }'; }
sh_out() { outln 'out() { printf %s "$@"; }'; }
sh_outln() { outln 'outln() { printf %s\\n "$@"; }'; }
sh_err() { outln 'err() { printf %s "$@" >&2; }'; }
sh_errln() { outln 'errln() { printf %s\\n "$@" >&2; }'; }

addPrefixedFunction 'sh' 'die' 'Message stderr and exit'
sh_die() {
  out 'die() { printf %s "${1}: " >&2; '
  # print error code ${1} (was ${2}) and exit with it
  out 'shift 1; printf %s\\n "$@" >&2; exit "${1}"; }'
}
# Defends against malicious ${2} but not malicious ${1}
# ${1} must be valid varname
addPrefixedFunction 'sh' 'eval_assign' 'Specify variable name at runtime to assign'
sh_eval_assign() { outln 'eval_assign() { eval "${1}"=\"${2}\"; }'; }

# Much thanks to Rich (https://www.etalabs.net/sh_tricks.html)
# Keeping to the analogy, this is ruby's p, but not really, so renamed
addPrefixedFunction 'sh' 'eval_escape'     "Escape for use in \`eval\`"
addPrefixedFunction 'sh' 'awk_eval_escape' "DOUBLE CHECK THIS WORKS"
#addPrefixedFunction 'awk_eval_escape' "Escape for use in \`eval\` in awkscript"
sh_eval_escape() { <<EOF cat -
eval_escape() { <&0 sed "s/'/'\\\\\\\\''/g;1s/^/'/;\\\$s/\\\$/'/"; }
EOF
}
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
sh_awk_eval_escape() { # TODO: Check if this is works
  <<EOF cat -
awk_eval_escape='
  function evalEscape(target) {
    gsub(/'\\''/, "'\\''\\\\\\\\\\'\\''", target);
    return "'\\''" target "'\\''";
  }
'
EOF
}

addPrefixedFunction 'sh' 'require' 'POSIX way to test program exists in ${PATH}'
sh_require() {
  <<EOF cat -
require() {
  for dir in \$( printf %s "\${PATH}" | tr ':' '\n' ); do
    [ -f "\${dir}/\${1}" ] && [ -x "\${dir}/\${1}" ] && return 0
  done
  return 1
}
EOF
}


addPrefixedFunction 'sh' 'prompt_color' \
  'Prompt with color and Basic Regular Expression validation'
# Want to use >/dev/tty (in `pc`) in case we are running this in subshell
sh_prompt_color() {
  ifNotRootIsReadableAndHas "${1}" sh_pc || sh_pc
  ifNotRootIsReadableAndHas "${1}" sh_fg_CLEAR || sh_fg_CLEAR
  <<EOF cat -
prompt() {
  pc "\${2}"; read -r value; pc "\${CLEAR}"
  while outln "\${value}" | grep -qve "\${1}"; do
    pc "\${3:-"\${2}"}"; read -r value
    pc "\${CLEAR}"
  done
  printf %s "\${value}"
}
EOF
}

addPrefixedFunction 'sh' 'prompt_stderr' \
  'Prompt without color and with Basic Regular Expression validation'
sh_prompt_stderr() {
  <<EOF cat -
prompt() {
  errln "\${2}"; read -r value
  while outln "\${value}" | grep -qve "\${1}"; do
    errln "${3:-"\${2}"}"; read -r value
  done
  printf %s "\${value}"
}
EOF
}

# TODO: Pick


addPrefixedFunction 'sh' 'match_any' "Same as 'contains' but match for many"
sh_match_any() {
  matchee="$1"; shift 1
  [ -z "${matchee}" ] && return 1
  for matcher in "$@"; do  # Literal match in case
    case "${matchee}" in "${matcher}") return 0 ;; esac
  done
  return 1
}

addPrefixedFunction 'sh' 'absolute_path' "Converts any path to an absolute path"
sh_absolute_path() {
  <<EOF cat -
absolute_path() (
  dir="\$( dirname "\${1}"; printf a )"; dir="\${dir%?a}"
  cd "\${dir}" || exit "\$?"
  wdir="\$( pwd -P; printf a )"; wdir="\${wdir%?a}"
  base="\$( basename "\${1}"; printf a )"; base="\${base%?a}"
  output="\${wdir}/\${base}"
  [ "\${output}" = "///" ] && output="/"
  printf %s "\${output%/.}"
)
EOF
}


addPrefixedFunction 'sh' 'print_do' "Prints or executes a command"
sh_print_do() {
  <<EOF cat -
print_do() {
  if "\${DRYRUN}"; then
    printf '"%s" ' "\$@"
    printf \\\\n
  else
    "\$@"
  fi
}
EOF
}




################################################################################
# Main
addPrefixedFunction 'sh' 'help' 'Display the help file'
sh_help() {
  ifNotRootIsReadableAndHas "${1}" sh_name || { sh_name; outln; }
  <<EOH cat -
exit_help() {
  <<EOF cat - >&2
SYNOPSIS
  \${NAME}

DESCRIPTION
  

OPTIONS
  -
    Special argument that says read from STDIN

  --
    Special argument that prevents all following arguments from being
    intepreted as options.
EOF
  exit 1
}
EOH
}

addPrefixedFunction 'sh' 'awk_help' 'Display the help file'
sh_awk_help() {
  ifNotRootIsReadableAndHas "${1}" sh_name || { sh_name; outln; }
  <<EOF cat -
exit_help() {
  printf %s\\n "SYNOPSIS" >&2
  printf %s\\n "  ${NAME} <JOB> [<arg> ...]" >&2

  printf %s\\n "" "OPTIONS" >&2
  <"${NAME}" awk '
    /^    "\\\${literal}" || case "\\\${1}/ { run = 1; }
    /^    esac/ { run = 0; }
    run && /^    in|^    ;;/ {
      sub(/^ *in /, "  ", \$0);
      sub(/^ *;; /, "  ", \$0);
      sub(/\\) *#/, "\\t", \$0);
      sub(/\\).*/, "", \$0);
      print \$0;
    }
  ' >&2

  exit 1
}
EOF
}

addPrefixedFunction 'sh' 'main_fixed' \
  'Main loop that handles options with no arguments'
sh_main_fixed() {
  <<EOF cat -
main() {
  # Dependencies

  # Options processing
  args=''; literal='false'
  for a in "\$@"; do
    "\${literal}" || case "\${a}"
      in --)         literal='true'; continue
      ;; -h|--help)  exit_help

      ;; -*) die FATAL 1 $(
        out "\"Invalid option '\${a}'. See \\\`\${NAME} -h\\\` for help\"" )
      ;; *)  args="\${args} \$( outln "\${a}" | eval_escape )"
    esac
    "\${literal}" && args="\${args} \$( outln "\${a}" | eval_escape )"
  done

  [ -z "\${args}" ] && exit_help
  eval "set -- \${args}"

}
EOF
}

addPrefixedFunction 'sh' 'main_variable' \
  'Main loop that handles options with arguments'
sh_main_variable() {
  <<EOF cat -
# Handles options that need arguments
main() {
  # Dependencies

  # Options processing
  args=''
  literal='false'
  while [ "\$#" -gt 0 ]; do
    "\${literal}" || case "\${1}"
      in --)        literal='true'; shift 1; continue
      ;; -h|--help) exit_help

      ;; -f)            echo 'do not need to shift'
      ;; -e|--example2) outln "-\${2}-"; shift 1

      ;; -*) die FATAL 1 $(
        out "\"Invalid option '\${1}'. See \\\`\${NAME} -h\\\` for help\"" )
      ;; *)  args="\${args} \$( outln "\${1}" | eval_escape )"
    esac
    "\${literal}" && args="\${args} \$( outln "\${1}" | eval_escape )"
    shift 1
  done

  [ -z "\${args}" ] && exit_help
  eval "set -- \${args}"

}
EOF
}

addPrefixedFunction 'sh' 'main_condensed' \
  'Main loop that where single-letter options can be combined'
sh_main_condensed() {
  <<EOF cat -
# Handles single character-options joining (eg. pacman -Syu)
main() {
  # Flags

  # Dependencies

  # Options processing
  args=''
  literal='false'
  while [ "\$#" -gt 0 ]; do
    if ! "\${literal}"; then
      # Split grouped single-character arguments up, and interpret '--'
      # Parsing '--' here allows "invalid option -- '-'" error later
      case "\${1}"
        in --)      literal='true'; shift 1; continue
        ;; -[!-]*)  opts="\$( outln "\${1#-}" | sed 's/./ -&/g' )"
        ;; --?*)    opts="\${1}"
        ;; *)       opts="regular" ;;  # Any non-hyphen value will do
      esac

      # Process arguments properly now
      for x in \${opts}; do case "\${x}"
        in -h|--help)     exit_help
        ;; -e|--example)  outln "-\${2}-"; shift 1

        ;; -*) die FATAL 1 $(
          out "\"Invalid option '\${1}'. See \\\`\${NAME} -h\\\` for help\"" )
        ;; *)  args="\${args} \$( outln "\${1}" | eval_escape )"
      esac done
    else
      args="\${args} \$( outln "\${1}" | eval_escape )"
    fi
    shift 1
  done

  [ -z "\${args}" ] && exit_help
  eval "set -- \${args}"

}
EOF
}


addPrefixedFunction 'sh' 'main_menu' \
  'For offering named choices, but no option processing yet'
sh_main_menu() {
  <<EOF cat -
$( sh_fg_BLUE    '/' )
$( sh_fg_RED     '/' )
$( sh_fg_GREEN   '/' )
$( sh_fg_YELLOW  '/' )
$( sh_fg_BLUE    '/' )
$( sh_fg_MAGENTA '/' )
$( sh_fg_CYAN    '/' )
$( sh_fg_CLEAR   '/' )

main() {
  [ "\$#" = 0 ] && eval "set -- \$( prompt '.*' "\$( outln \\
    "\${CYAN}help\${CLEAR}" \\
    "\${CYAN}example\${CLEAR} <arg> [<arg2>]" \\
    "\${CYAN}example2\${CLEAR} <dir> <arg2> ..." \\
    "Enter one of the options: \${CYAN}" \\
  )" )"
  cmd="\${1}"; shift 1
  case "\${cmd}"
    in h*)  exit_help

    ;; e*)  echo 1
    ;; 2)   echo 2

    *)      exit_help
  esac
}
EOF
}


addPrefixedFunction 'sh' 'init_default' 'Init for a standard shell script'
sh_init_default() {
  <<EOF cat -
$( sh_hashbang_sh '/' )

$( sh_awk_name '/' )

$( sh_help '/' )

$( sh_main_variable '/' )

# Helpers
$( sh_outln '/' )
$( sh_die '/' )
$( sh_eval_escape '/' )

<&0 main "\$@"
EOF
}

addPrefixedFunction 'sh' 'init_menu' 'Init for a script with menu of options'
sh_init_make() {
  <<EOF cat -
$( sh_hashbang_sh '/' )

$( sh_name '/' )

$( sh_awk_help '/' )

$( sh_main_fixed '/' )

my_make() {
  case "\${1}"
    in hel)
    ;; help|*)  printf %s\\n "'\${1}' is not a supported command" >&2; exit_help
  esac
}

# Helpers
$( sh_outln '/' )
$( sh_die '/' )
$( sh_eval_escape '/' )

<&0 main "\$@"
EOF
}

addPrefixedFunction 'sh' 'init_menu' 'Init for a script with menu of options'
sh_init_menu() {
  <<EOF cat -
$( sh_hashbang_sh '/' )

$( sh_name '/' )

$( sh_awk_help '/' )

$( sh_main_fixed '/' )

# Helpers
$( sh_outln '/' )
$( sh_pc '/' )
$( sh_die '/' )
$( sh_eval_escape '/' )

$( sh_prompt_color '/' )

<&0 main "\$@"
EOF
}

################################################################################
# For other languages

addPrefixedFunction 'sh' 'py_make' "Python virtual environment runner"
sh_py_make() {
  <<EOF cat -
#!/bin/sh
# Prefix commands with ./make.sh to run with virtual environment, e.g.
#     ./make.sh pip install -e .[dev]
#     ./make.sh python app.py

$( sh_cd_project )

. venv/bin/activate || { printf %s\\n "Error sourcing venv" >&2; exit 1; }
"\$@"

EOF
}

addPrefixedFunction 'sh' 'post_data' "POST default Content-Type header"
sh_post_data() {
  <<EOF cat -
curl -X POST -d 'lang=en&amount=12' "localhost:8000/api"
EOF
}

addPrefixedFunction 'sh' 'post_form' "POST default x-www-form-urlencoded header"
sh_post_form() {
  <<EOF cat -
curl -X POST -F 'lang=en' -F 'amount=12' "localhost:8000/api"
EOF
}

addPrefixedFunction 'sh' 'post_json' "POST JSON"
sh_post_json() {
  <<EOF cat -
curl -X POST \\
  -H "Content-Type: application/json" \\
  -d '{"lang": "en", "amount": 12}' \\
  "localhost:8000/api"
EOF
}




