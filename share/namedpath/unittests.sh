#!/usr/bin/env sh

me="$( dirname "${0}"; printf a )"; me="${me%?a}"
me="$( realpath "${me}"; printf a )"; me="${me%?a}"
env1() { env TOPRINT="${me}/cdpath1::${me}/cdpath2" \
  PATH="${me}:${PATH}" "${me}/namedpath.sh" "${@}"; }
env2() { env TOPRINT="${me}/cdpath1:${me}/cdpath2:${me}/cdpath3" \
  PATH="${me}:${PATH}" "${me}/namedpath.sh" "${@}"; }

COUNT=0
test_path() {
  cd "${me}" || exit 1
  COUNT="$((COUNT + 1))"
  convert="$(env"${1}" "${2}")"
  if [ "${convert}" = "${3}" ]; then
    printf %s\\n "${COUNT} test success -- '${2}'"
  else
    printf %s\\n "${COUNT} test failure"\
      "  - '${2}' changed to '${convert}'" \
      "  - '${2}' expected   '${3}'"
  fi
}
#env1 -p

#a="$(cd "${me}" && env1 'targ')"; [ "${a}" = "" ] && printf \\n

#a="$(cd "${me}" && env1 'targ')"; [ "${a}" = "" ] && printf \\n
test_path 1 './target' "${me}/target"
test_path 1 './target/' "${me}/target"
test_path 1 '././././target' "${me}/target"
test_path 1 '././././target/' "${me}/target"
test_path 1 './a/b/c/../.././target/..' "${me}/a"
test_path 1 './a/b/c/../.././target/../' "${me}/a"
test_path 1 'a/.././target' "${me}/target/target"
test_path 1 'a/../../target' "${me}/target"
test_path 1 'a/./././b/..' "${me}/target/t-a"
test_path 1 "../../../../../../../a/.." "/"
test_path 1 "../../../../../../../a/../" "/"
test_path 1 "${HOME}/../../a/.." "/"
test_path 1 "${HOME}/../../a/../" "/"
test_path 1 "${HOME}/../../.." "/"
test_path 1 "${HOME}/../../../" "/"
test_path 1 "/../././././../a///b/.././/../../../" "/"
test_path 1 "/../../.." "/"
test_path 1 "/././." "/"
test_path 1 "/../././.." "/"
test_path 1 "/../././../" "/"
test_path 1 "/.././/././a/../b/.." "/"
test_path 1 "/a/../b/c/../../d" "/d"
test_path 1 "uaslkjdf/../b/c/../../d" "${me}/d"
exit
strace -c namedpath.sh "targ"
time -v namedpath.sh "targ"
bash -c namedpath.sh -l 2>&1 | grep -A 2 -B 1 -F 'profiling_mark'
#env1 
