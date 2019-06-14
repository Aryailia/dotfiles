#!/usr/bin/env sh
# Preserves newlines and does not print anything extra
# TODO: Look at namedpath, add dealing with trailing '/.' and trailing '/..'
# TODO: trailing dots for relative paths too, probably

path="$(</dev/null awk -v a="$(<&0 cat -; echo a)" 'END{
  gsub(/\/\.\/(\.\/)*/, "/", a);
  gsub("//*" , "/", a);
  while (!match(a, "^[^/]*/\\.\\./") && sub("/[^/]*/\\.\\./", "/", a));
  # The right match needs to double "[^/]" because no "+" regexp and because
  # it would also match with an absolute path without the plus. Other
  # empty sandwhiches between two "/" are already taken care of
  if (!match(a, /^\.\./) && match(a, "^[^/][^/]*/\\.\\./"))
    sub("^[^/]*/\\.\\./", "", a);
  printf("%s", a);
}')"
printf %s "${path%a}"
