#!/usr/bin/env sh

name="$(basename "$0"; printf a)"; name="${name%?a}"

show_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${name}

DESCRIPTION
  
EOF
}



# TODO: Add switch for PS1 in case prompt.sh not found
# TODO: Add verbose flag?
# TODO: Add flag for eval_escape
main() {
  case "$1" in
    -h|--help)  show_help; exit 1 ;;
    -p|--prompt)
      root="$(tmux display-message -t "${TARGET_PANE}" \
        -p "#{pane_current_path}"; printf a)"
      root="${root%?a}" 
      final="$(tmux capture-pane -peC -t "${TARGET_PANE}" \
        | tac \
        | sed '/^\\033\[1m/{ s/^\\033\[1.*\\033\[49m //; q }' \
        | tac
      )"
      autocomplete "${root}" "${final}"
      ;;

    #-t|--tmux2)
    #  ps1="$(tmux capture-pane -peC -t "${TARGET_PANE}" \
    #    | awk '/\S/{ a= $1 F; } END{ print a; }' \
    #    | sed 's/[^^]/[&]/g; s/\^/\\^/g'
    #  )"
    #  printf %s "$ps1"
    #  ;;

    -t|--tmux-pane)
      notify.sh "${TARGET_PANE}"
      root="$(tmux display-message -t "${TARGET_PANE}" \
        -p "#{pane_current_path}"; printf a)"
      root="${root%?a}" 

      final="$(tmux capture-pane -peC -t "${TARGET_PANE}" \
        | awk '/\S/{ a = $(NF); }
          # Delete ANSI escape codes, then print without newline
          END{ gsub(/\\033\[[0-9]*;?[A-Za-z]/, "", a); printf("%s", a); }
        '
      )"
      from_parameter_fragment "${root}" "${final}"
      ;;

    -i)  autocomplete_from_one_parameter '.' "${TARGET_PANE}" ;;
    -w)  working_directory_files "${TARGET_PANE}" ;;
    -n|--normalise)  prints "${TARGET_PANE}" | normalise_dir_base ;;
    -l|--list-path)  list_null_separated_path_executables | fzf --read0 ;;
    *)  puts 'pass an argument' >&2; exit 1 ;;
  esac

}


from_command_fragment() {
  if echo yo | sed '^:' ; then
    echo yo
  elif :; then
    echo yo
  fi
}

from_parameter_fragment() {
  # Special case-by-case custom auto-completion
  if ! :; then
    :

  # Command that is expecting a file/command from path
  # `dash` will return true whenever a path ending in slash is given
  elif ! nonempty_match_suffix "$*" '/' && require "$*"; then
    autocomplete_for_files_and_path "$@"


  # Fill out a half completed path or this maps onto a previous argument
  # (since tmux capture-pane does have cursor so there is extra whitespace)
  else
    autocomplete_for_pathname "$@"
  fi
}

autocomplete_custom() {
  echo 'adsf'
}

autocomplete_for_pathname() {
  \cd "$1" || return
  shift 1

  require 'namedpath.sh' || die 1 'FATAL' "need namedpath.sh"
  path="$(namedpath.sh "$*" | normalise_dir_base; printf a)"; path="${path%a}"
  dir="${path%/*}"
  base="${path##*/}"
  prompt="$*";
  if [ -d "$*" ]; then
    prompt="${prompt}/"
    [ -n "$*" ] && ! nonempty_match_suffix "$*" '/' && printf '/'
  fi

  result="$(
    \cd "${dir}" >/dev/null 2>&1 || exit 1
    working_directory_files "${base}" | search --prompt="${prompt}"
    print a
  )"
  result="${result%a}"
  printf %s "${result#./${base}}" #| eval_escape
}



autocomplete_for_files_and_path() {
  \cd "$1" || return
  shift 1

  # $PATH cannot have the weirder characters, yay
  result="$(
    # `uniq` cannot deal with null characters so cannot use here
    { working_directory_files; list_null_separated_path_executables; } \
    | search --prompt "$* {} > "
    printf a
  )"
  result="${result%a}"
  printf %s "${result#./}" #| eval_escape
}


working_directory_files() {
  # TODO: test if $1 containing * will match './*/' or interpreted as wildcard
  # This does not deal with files that have newlines
  # The only way for fzf to deal with newlines is to use -print0
  # -print0 is not POSIX, so using `-exec printf \000 +` since that is POSIX
  # Though '+' is a newer addition to POSIX and may not be on older systems
  # -maxdepth and -mindepth are not part of POSIX
  find . ! -name '.' -path "./$1*" -exec printf '%s\000' '{}' +
}

# for the options
search() {
  # Want the newline removal from $()
  # --delimiter='/' --with-nth='2..' serve to skip the first ./
  # --exit-0 for when passed nothing (`find` found nothing) 
  <&0 fzf --read0 --print0 --delimiter='/' --with-nth='2..' \
    --bind=tab:print-query --no-sort --select-1 --exit-0 \
    "$@"
}




# Helpers
die() {
  c="$1"
  t="$2"
  shift 2;
  exit "$c"
}

# Ensures there is both a directory and (possibly empty) base separated by a
# slash, in other words, ensures that there is a slash in the path.
# Adds a trailing slashes to directories and interprets in text tilde
# Auto-completion happens before shell expansion of ~
#
# To test: '~' '~/' '/' 'a' 'dir-that-exists' '/usr' './' './dir-that-exists'
normalise_dir_base() {
  input="$(cat -; printf a)"; input="${input%a}"
  # Literal tilde would be escaped anyway so would not start our sequence
  # Three checks: == '~' ||  (!= '' && == '~/')
  if [ "${input}" = '~' ] || nonblank_match_prefix "${input}" '~/'
    then detilde="${HOME}${input#\~}"
    else detilde="${input}"
  fi

  # This tests both if "${detilde}" does not start with '/' or is empty
  # Both of which cases we want to add './'
  [ "${detilde#/}" = "${detilde}" ] && prints "./"
  prints "${detilde}"
  [ -d "${detilde}" ] && prints '/'  # Add trailing slash
}

list_null_separated_path_executables() {
  for dir in $(puts "${PATH}" | tr ':' '\n' | uniq); do
    for arg in "${dir}"/* "${dir}"/.[!.]* "${dir}"/..?*; do
      [ -x "${arg}" ] && printf '%s\000' "${arg##*/}"
    done
  done
}

require() {
  for dir in $(printf %s "${PATH}" | tr ':' '\n'); do
    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0
  done
  return 1
}
prints() { printf %s "$@"; }
puts() { printf %s\\n "$@"; }
die2() { c="$1"; t="$2"; shift 2; puts "$t: '${name}'" "$@" >&2; exit "$c"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

nonempty_match_suffix() { [ "${1%$2}" != "$1" ]; }
nonblank_match_prefix() { [ "${1#$2}" != "$1" ]; }

main "$@"
