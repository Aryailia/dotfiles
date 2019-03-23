#!/usr/bin/env sh

dotconfig="../.config"
shell_config="${dotconfig}/aliasrc"
bash_config="${HOME}/"
vifm_config=""

puts() { printf %s\\n "$@"; }
die() { exitcode="$1"; shift 1; printf %s\\n "$@" >&2; exit "${exitcode}"; }

main() {
  for arg in "$@"; do
    case "${arg}" in
      c) puts a ;;
      bash) puts a ;;
      vifm) puts a ;;
    esac
  done
}


main "$@"
