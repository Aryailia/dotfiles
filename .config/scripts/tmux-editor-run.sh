#!/bin/sh

#$1: filetype
#$2: path to 

# run: echo %

eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }

case "$#"
in 0|1)  die FATAL 1 "Missing arguments"
;; 2)    filetype="${1}"; path="${2}"
;; *)    die FATAL 1 "Too many arguments"
esac

[ -n "${TMUX}" ] || die FATAL 1 "Not running inside of tmux"

<<EOF IFS=, read -r _ regexp1 regexp2
$( {
  printf %s\\n 'sh,^ *#run:,'
  printf %s\\n 'awk,^ *#run:,'
  printf %s\\n 'pl,^ *#run:,'
  printf %s\\n 'perl,^ *#run:,'

  printf %s\\n 'dockerfile,^ *#run:,'

  printf %s\\n 'py,^ *#run:,'
  printf %s\\n 'python,^ *#run:,'
  printf %s\\n 'go,^ *\/\/run:,'
  printf %s\\n 'rs,^ *\/\/run:,'
  printf %s\\n 'rust,^ *\/\/run:,'
  printf %s\\n 'java,^ *\/\/run:,'
  printf %s\\n 'js,^ *\/\/run:,'
  printf %s\\n 'ts,^ *\/\/run:,'
  printf %s\\n 'javascript,^ *\/\/run:,'
  printf %s\\n 'typescript,^ *\/\/run:,'
  printf %s\\n 'zig,^ *\/\/run:,'

  printf %s\\n 'sass,^ *\/\/run:,'
  printf %s\\n 'scss,^ *\/\/run:,'
  printf %s\\n 'html,^ *<!--run:,-->.*$'
  printf %s\\n 'rmd,^ *<!--run:,-->.*$'
  printf %s\\n 'md,^ *<!--run:,-->.*$'
  printf %s\\n 'tex,^ *%run:,'
} | awk -v FS="," "/^${filetype},/ { print \$0; exit 0; }"
)
EOF

# @TODO @BUG: if language not found, it opens two tmux windows

# There's no good reason to use % as a special keyword
# Only using it because vim uses it to expand to the filename
awk_program='
BEGIN { exit_code = 1; }
/'"${regexp1}.*${regexp2}"'/ {
  sub(/'"${regexp1}"'/, "", $0);
  sub(/'"${regexp2}"'/, "", $0);
  gsub(/@/, "@A", $0);
  gsub(/%%/, "@P", $0);
  gsub(/%/, path, $0);
  gsub(/@P/, "%", $0);
  gsub(/@A/, "@", $0);
  print $0;
  exit_code = 0;
  exit 0;
}
END { exit(exit_code); }
' || notify.sh "Syntax error in awk for $0"

# Add spaces before to use bash's ignore history when pre-spaced
tmux-alt-pane.sh send-keys "  $(
  if [ -n "${regexp1}" ] && awk -v path="${path}" "${awk_program}" "${path}"; then
    :
  else
    printf %s "build.sh run --temp "
    printf %s "${path}" | eval_escape
  fi
)" Enter
