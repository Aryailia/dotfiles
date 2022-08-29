#!/usr/bin/env sh

shortcuts="${HOME}/.config/rc/shortcutsrc"
shell_shortcuts="${HOME}/.config/named_directories"
#vifm_shortcuts="${HOME}/.config/vifm/directory_shortcuts"

require() { command -v "$1" >/dev/null 2>&1; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }

require "${shortcuts}" || die FATAL 1 "Need '${shortcuts}' script"

mkdir -p "${shell_shortcuts}"    # Put the shortcuts inside this directory
#mkdir -p "${vifm_shortcuts%/*}"  # basedir, probably no need to check edge cases

# Expect eval-escaped (shell-quotable) output from `${shortcuts}`
eval "set -- $("${shortcuts}")" || die FATAL 1 "Error with '${shortcuts}'"

## Sanitise ${shortcuts} output and create the symlinks for the shell shortcuts
## STDERR is to the tty, STDOUT is to ${map}
#rm "${shell_shortcuts}"/*
#map="$(sh -c "$(<<EOF cat -
#  while [ "\$#" -ge 2 ]; do
#    path="\${2#${HOME}}"
#    [ "\${path}" != "\$2" ] && path="~\${path}"
#    if [ -e "\$2" ] && ln -s \$2 "${shell_shortcuts}/"\$1; then
#      printf "%s\\\\n"        "SUCCESS: \$1 -> \${path}" >&2
#      printf "'%s' '%s'\\\\n" "\$1" "\$2"
#    else
#      printf "%s\\\\n" "FAIL: '\${path}' does not exist" >&2
#    fi
#    shift 2
#  done
#EOF
#)" '_' "$@")"

# Sanitise ${shortcuts} output and create the symlinks for the shell shortcuts
# STDERR is to the tty, STDOUT is to ${map}
rm "${shell_shortcuts}"/*
while [ "$#" -ge 2 ]; do
  path="${2#"${HOME}"}"
  [ "${path}" != "$2" ] && path="~${path}" # replace '${HOME}' with '~'
  if [ -e "$2" ] && ln -s $2 "${shell_shortcuts}/"$1; then
    printf %s\\n         "SUCCESS: $1 -> ${path}" >&2
    printf "'%s' '%s'\n" "$1" "$2"
  else
    printf %s\\n "FAIL: '${path}' does not exist" >&2
  fi
  shift 2
done

## Vifm
#FS="' *'|'"
#puts "${map}" | awk -v FS="${FS}" '(1) { print("mark " $2 " " $3); }' \
#  >"${vifm_shortcuts}"

