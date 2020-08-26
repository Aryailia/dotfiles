#!/usr/bin/env sh

OPENING='--- opening ---'
CLOSING='--- closing ---'
REPLACE='./util-replace.sh'

NEWLINE='
'
LIST_OF_TESTS=''
TOTAL_TEST_COUNT='0'
register_test() {
  # $1: name of function to run (doubles as its description)
  [ "${1#*[!A-Za-z0-9_]}" != "${1}" ] && { errln "bad test name"; exit 1; }
  TOTAL_TEST_COUNT="$(( TOTAL_TEST_COUNT + 1 ))"
  LIST_OF_TESTS="${LIST_OF_TESTS}${NEWLINE}${1}"
}

main() {
  TEMP="$( mktemp )"
  trap "rm -f \"${TEMP}\"" EXIT

  register_test "first_test"
  register_test "empty_file"
  register_test "no_closing_tag"
  register_test "no_opening_tag"
  register_test "no_tags"

  # run tests
  COUNT="0"
  for f in ${LIST_OF_TESTS}; do
    COUNT="$(( COUNT + 1 ))"
    # pass name so they can reprint name on error
    "${f}" "${f}" || break    # errors handled internally
    errln "'${f}' completed"  # success handled here
  done
  errln "${COUNT} of ${TOTAL_TEST_COUNT} tests run"
}

in_file_replace() {
  # $1: filename
  # $2: items to replace
  [ -f "${1}" ] || { errln "FATAL: 1 - File '${1}' does not exist; ";  exit 1; }

  _replacement="$( <"${1}" "${REPLACE}" \
    "${OPENING}" \
    "${2}" \
    "${CLOSING}" \
  ; printf a )"
  _replacement="${_replacement%a}"

  printf %s "${_replacement}" >"$1"
}

################################################################################
empty_file() {
  printf '' >"${TEMP}"
  in_file_replace "${TEMP}" "this should not appear in file" || return 1
  assert_eq "${1}" "${TEMP}" ""
}

################################################################################
first_test() {
  <<EOF cat - >"${TEMP}"
the cat in the hat
${OPENING}
replace this
${CLOSING}
me
EOF

  body="boop"
  in_file_replace "${TEMP}" "${body}" || return 1
  rhs="$(<<EOF cat -
the cat in the hat
${OPENING}
${body}
${CLOSING}
me
EOF
  printf a
)"
  rhs="${rhs%a}"  # here-doc has an extra newline, but both are here-doc
  assert_eq "${1}" "${TEMP}" "${rhs}"
}

################################################################################
no_closing_tag() {
  lhs="$(<<EOF cat -
かきくけこabcde
さしすせそfghijklmn
${OPENING}
I
forgot the
end
EOF
  printf a
)"
  lhs="${lhs%${NEWLINE}a}"  # here-doc has an extra newline
  printf %s "${lhs}" >"${TEMP}"

  body="你e好l嗎
asdf哈哈"
  in_file_replace "${TEMP}" "${body}" || return 1
  assert_eq "${1}" "${TEMP}" "${lhs}"
}

################################################################################
no_opening_tag() {
  lhs="$(<<EOF cat -
かきくけこabcde
さしすせそfghijklmn
I
forgot the
end
${ENDING}
EOF
  printf a  # this has extra newline
)"
  lhs="${lhs%${NEWLINE}a}"  # here-doc has an extra newline
  printf %s "${lhs}" >"${TEMP}"

  body="你e好l嗎 asdf哈哈"
  in_file_replace "${TEMP}" "${body}" || return 1
  assert_eq "${1}" "${TEMP}" "${lhs}"
}

################################################################################
no_tags() {
  lhs="$(<<EOF cat -

かきくけこabcde
さしすせそfghijklmn
I have no tags

EOF
  printf a  # this has extra newline
)"
  lhs="${lhs%${NEWLINE}a}"  # here-doc has an extra newline
  printf %s "${lhs}" >"${TEMP}"

  body="你e好l嗎 asdf哈哈"
  in_file_replace "${TEMP}" "${body}"
  assert_eq "${1}" "${TEMP}" "${lhs}"
}

assert_eq()  {
  # $1: test name
  # $2: lhs
  # $3: rhs
  _file="$( cat "${2}"; printf a )"
  _file="${_file%a}"
  if [ "${_file}" != "${3}" ]; then
    errln "FATAL: 1 - ${1}"
    errln ""
    errln "<------------------------------------------------"
    errln "${_file}"
    errln "================================================="
    errln "${3}"
    errln "------------------------------------------------>"
    return 1
  fi
  return 0
}

out() { printf %s "$@"; }
outln() { printf %s\\n "$@"; }
errln() { printf %s\\n "$@" >&2; }

main "$@"
