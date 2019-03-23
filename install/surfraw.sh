#!/usr/bin/env sh

url="https://gitlab.com/surfraw/Surfraw"
dest="${HOME}/ime/source/surfaw"

die() { printf '%s' "$@"; exit 1; }

command -v "autoconf" >/dev/null 2>&1 || die "FATAL: Requires 'autoconf'"
command -v "git" >/dev/null 2>&1 || die "FATAL: Requires 'git'"

git-cloneupdate.sh "${url}" origin master "${dest}"
[ -d "${dest}" ] || die "Directory '${dir}' was not created properly"
cd "${dest}"
./prebuild
./configure --prefix="$PREFIX" --disable-opensearch
#./configure --prefix="$PREFIX" --sysconfdir="$PREFIX/etc" --disable-opensearch
make
