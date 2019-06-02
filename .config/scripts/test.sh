#!/usr/bin/env sh

name="$(basename "$0"; printf a)"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
Usage: ${name} TESTNAME
Random test stuff, your options are:${help_list}
EOF
}

main() {
  list2="
    pl,powerline
    tc,truecolors
    u,unicode
  "
  list="powerline truecolors unicode"
  help_list=""


  for item in ${list}; do
    help_list="${help_list}$(printf '\n  %s' "${item}")"
  done
  for item in ${list2}; do
    help_list="${help_list}$(printf '\n  %s' "$(get ${item} 1)")"
  done

  done='false'
  for arg in "$@"; do
    for item in ${list2}; do
      short="$(get "${item}" 0)"
      full="$(get "${item}" 1)"
      case "${arg}" in
        -h|--help)  show_help; exit 0 ;;
        "${short}"|"${full}")  "${full}"; done="true" ;;
      esac
    done
  done
  "${done}" || { show_help; exit 1; }
}

get() {
  [ "$2" = 0 ] && printf %s "${1%,*}"
  [ "$2" = 1 ] && printf %s "${1#*,}"
}


powerline() {
  # White on red bg 'hello', powerline transition, white on cyan bg 'there'
  bash -c "
    printf '%s' $'\033[1;37;41m hello \033[1;31;46m\uE0B0 \033[1;37mthere '
  "
}

truecolors() {
  # could do #!/usr/bin/awk -f
  # https://gist.github.com/XVilka/8346728
  awk 'BEGIN{
    s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
    for (colnum = 0; colnum<77; colnum++) {
      r = 255-(colnum*255/76);
      g = (colnum*510/76);
      b = (colnum*255/76);
      if (g>255) g = 510-g;
      printf "\033[48;2;%d;%d;%dm", r,g,b;
      printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
      printf "%s\033[0m", substr(s,colnum+1,1);
    }
    printf "\n";
  }'
}

unicode() {
  echo WIP
}

main "$@"
