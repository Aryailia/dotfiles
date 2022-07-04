#!/bin/sh

# Browses a YAML file interactively via `fzf` and `yq-go`

escape() { <&0 sed 's/"/\\"/g'; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }

NL="
"
database="${DOTENVIRONMENT}/notes/cts.yml"
[ -f "${database}" ] || die FATAL 1 "File does not exist '${database}'"

#run: sh %
case "${1}"
  in "preview")
    <"${database}" yq-go "${2}[\"${3}\"]"

  ;; edit)  exec "${EDITOR}" "${database}"
  ;; "")
    choice="$( <"${database}" yq-go "keys | join(\"${NL}\")" | fzf )" \
      || exit "$?"
    search=".[\"${choice}\"]"
    escaped_search="$( printf %s\\n "${search}" | escape )"

    #printf %s\\n "${search}"
    #echo yo | fzf --preview="printf %s\\\\n '${0}' preview \"${search}\" {}"
    #printf %s\\n fzf --preview="'${0}' preview ${search} {}"
    #exit
    printf %s\\n "${search}"
    #exit
    while <"${database}" yq-go "${search} | keys" >/dev/null 2>&1; do
      choice="$(
        # preview for fzf seems quirky, it doens't like double quotes
        # and it treets single quotes specially
        <"${database}" yq-go "${search} | keys | join(\"${NL}\")" \
          | fzf --preview="'${0}' preview \"${escaped_search}\" {}"
      )" || exit 1
      search=".[\"${choice}\"]"
      escaped_search="$( printf %s\\n "${search}" | escape )"
    done
    <"${database}" yq-go "${search}" | clipboard.sh -w
  ;; *)  die FATAL 1 "Unexpected argument '${1}'"
esac


eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
