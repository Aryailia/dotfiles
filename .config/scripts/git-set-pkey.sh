#!/bin/sh

SSH_DIR="${HOME}/.ssh"
list_private_keys() {
  for f in "${SSH_DIR}"/* "${SSH_DIR}"/.*; do
    [ -e "${f}" ] || continue
    [ -e "${f}.pub" ] || continue
    f="${f#"${SSH_DIR}/"}"
    printf %s\\n "${f}"
  done
}

#v="$( git version )"
#v="${v#git version }"
#major="${v%%.*}"
#printf %s\\n "${major}"
#minor="$( printf %s\\n "${v#"${major}."}" | sed 's/\..*//' )"
#printf %s\\n "${minor}"

is_supported="$( git version | awk '{
  gsub("git version ", "");
  split($0, semver, ".")
  # check if >= 2.10
  if ((semver[1] == 2 && semver[2] >= 10) || semver[1] > 2) {
    print "true";
  } else {
    printf "false";
  }
}' )"

if ! "${is_supported}"; then 
  printf %s\\n "Need git < 2.10 does not support core.sshCommand" >&2
  printf %s\\n "You will have to configure it by host in the SSH config file" >&2
  exit 1
}
git rev-parse --is-inside-work-tree >/dev/null || exit "$?"

private_key="$( list_private_keys | fzf )" || exit "$?"
git config core.sshCommand "ssh -i ~/".ssh/${private_key}" -F /dev/null"
printf %s\\n "Setting to ssh with ${private_key}" >&2
