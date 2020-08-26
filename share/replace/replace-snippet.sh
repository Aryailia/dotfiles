replace() {
  _error='0'
  # Process till opening tag (or end-of-stdin)
  eat_till "$1" || return 1

  # Process till the closing tag (or end-of-stdin)
  _buffer="$(
    eat_till "$3"
    e="$?"
    printf a
    return "${e}"
  )" || _error="2"
  _buffer="${_buffer%a}"
  if [ "${_error}" = '2' ]
    then out "${_buffer}"; return "${_error}"
    else outln "${2}" "${3}"
  fi

  # Process till end-of-stdin
  while IFS= read -r _line; do
    outln "${_line}"
  done || out "${_line}"
}

eat_till() {
  while IFS= read -r _line; do
    outln "${_line}"
    [ "${_line}" != "${_line#"${1}"}" ] && return 0
  done || out "${_line}"  # if we hit end, `read` sets "${_line}" and errors
  [ "${_line}" != "${_line#"${1}"}" ]  # check last line
}
