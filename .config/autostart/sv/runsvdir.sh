#!/bin/sh
# https://docs.voidlinux.org/config/services/user-services.html

eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }

user="$( id -un )"
dir="${HOME}/${0%.sh}-${user}"

[ -n "${SVDIR}" ] || die FATAL 1 "SVDIR not set by ~/.profile"
[ -d "${SVDIR}" ] || die FATAL 1 "SVDIR is not a directory"
escaped_svdir="$( printf %s\\n "${SVDIR}" | eval_escape )"

# Creating the file ~'/.config/autorun/sv/runsvdir-<me>/run'
mkdir -p "${dir}"
<<EOF cat - >"${dir}/run"
#!/bin/sh

export  UID="$( id -u )"
export USER="${user}"
export HOME="/home/\${USER}"

groups="\$( id -Gn "\${USER}" | tr ' ' ':' )"

exec chpst -u "\${USER}:\${groups}" runsvdir -P ${escaped_svdir}
EOF

chmod 755 "${dir}/run"  # Must be runnable
