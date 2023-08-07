#!/bin/sh

derive_http() {
  case "${1}" in '')  printf %s\\n "Unsupported provider" >&2; exit 1
    ;; git@github.com:*)      printf %s\\n "https://github.com/${1#*:}"
    ;; https://github.com/*)  printf %s\\n "${1}"
    ;; *)  printf %s\\n "Unsupported provider: ${1}" >&2; exit 1
  esac
}

derive_ssh() {
  case "${1}" in '')  printf %s\\n "Unsupported provider" >&2; exit 1
    ;; git@github.com:*)      printf %s\\n "${1}"
    ;; https://github.com/*)  printf %s\\n "git@github.com:${1#https://*/}"
    ;; *)  printf %s\\n "Unsupported provider: ${1}" >&2; exit 1
  esac
}

if [ "${1}" = '' ]; then
  url="$( git remote get-url origin )" || {
    printf %s\\n "No remote alias 'origin', specify the clone url"
    exit 1
  }
else
  url="${1}"
  git remote remove origin 2>/dev/null
fi
ssh_url="$(  derive_ssh  "${url}" )"
http_url="$( derive_http "${url}" )"
git remote add            origin "${http_url}"
git remote set-url --push origin "${ssh_url}"
git remote -v
