" Use sh (usually maps to dash terminal) for better POSIX compliance
"noremap <silent> <leader>2 :call BuildAndRun($TMPDIR . '/preview', 'chmod 755 ' . $TMPDIR . '/preview', $TMPDIR . '/preview')<CR>
"noremap <silent> <leader>3 :call PreviewOpen($TERMINAL . ' -e')<CR>
"noremap <silent> <leader>4 :call PreviewClose()<CR>
"noremap <silent> <leader>l :call PreviewSendLine('shellcheck ' . expand('%:p'))<CR>

let b:ale_lint_on_text_changed = 'never'
let b:ale_lint_on_insert_leave = 0
let b:ale_lint_on_save = 1
let b:ale_lint_on_enter = 0

function! Lint()
endfunction

function! s:RunDefault()
  vertical T sh -c %
endfunction

function! s:RunWithArguments(cmdline)
  execute('vertical T ' . a:cmdline)
endfunction

function! Run()
  write
  call RunCmdlineOverload('#run: ',
    \ function('s:RunDefault'), function('s:RunWithArguments'))
endfunction

function! Build()
  call Run()
endfunction

" Snippets
inoremap <unique> <buffer> <LocalLeader>sbsh
  \ #!/usr/bin/env sh
inoremap <unique> <buffer> <LocalLeader>sbawk
  \ #!/usr/bin/awk -f
inoremap <unique> <buffer> <LocalLeader>sbpython
  \ #!/usr/bin/env python

inoremap <unique> <buffer> <LocalLeader>glob * .[!.]* ..?*
inoremap <unique> <buffer> <LocalLeader>name
  \ name="$( basename "$0"; printf a )"; name="${name%?a}"

" Using print color `pc` function
imap <unique> <buffer> <LocalLeader>prompt1
  \ <C-o>:if ! search('\m^ *pc() *{', 'bnw')<CR>
  \  execute "normal i<LocalLeader>pc\n"<CR>
  \endif<CR>
  \<C-o>:setlocal paste<CR>
  \prompt() {<CR>
  \  pc "${2}"; read -r value; pc "${CLEAR}"<CR>
  \  while outln "${value}" <bar> grep -qve "$1"; do<CR>
  \    pc "${3:-"$2"}"; read -r value<CR>
  \    pc "${CLEAR}"<CR>
  \  done<CR>
  \  printf %s "${value}"<CR>
  \}<CR>
  \<C-o>:setlocal nopaste<CR>
" Without colors and through STDERR (part of '<LocalLeader>init')
inoremap <unique> <buffer> <LocalLeader>prompt2
  \ <C-o>:setlocal paste<CR>
  \prompt() {<CR>
  \  errln "${2}"; read -r value<CR>
  \  while outln "${value}" <bar> grep -qve "$1"; do<CR>
  \    errln "${3:-"$2"}"; read -r value<CR>
  \  done<CR>
  \  printf %s "${value}"<CR>
  \}
  \<C-o>:setlocal nopaste<CR>

" Neither `which` nor `command -v` are defined in POSIX
" Some systems do not have `which` or it does not error code
" For some shells (like 'dash') `command -v` works more like `test -e`
inoremap <unique> <buffer> <LocalLeader>req
  \ <C-o>:setlocal paste<CR>
  \require() {<CR>
  \  for dir in $( printf %s "${PATH}" <Bar> tr ':' '\n' ); do<CR>
  \    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0<CR>
  \  done<CR>
  \  return 1<CR>
  \}
  \<C-o>:setlocal nopaste<CR>


" Defends against malicious $2 but not malicious $1. $1 must be valid varname
inoremap <unique> <buffer> <LocalLeader>assign
  \ eval_assign() { eval "$1"=\"$2\"; }

" `p` is for /dev/tty, the `c` in `pc` represents colour
inoremap <unique> <buffer> <LocalLeader>p
  \ p() { printf %s "$@" >/dev/tty; }
inoremap <unique> <buffer> <LocalLeader>pln
  \ pln() { printf %s\\n "$@" >/dev/tty; }
inoremap <unique> <buffer> <LocalLeader>pc
  \ pc() { printf %b "$@" >/dev/tty; }
inoremap <unique> <buffer> <LocalLeader>pcln
  \ pcln() { printf %b\\n "$@" >/dev/tty; }
inoremap <unique> <buffer> <LocalLeader>out
  \ out() { printf %s "$@"; }
inoremap <unique> <buffer> <LocalLeader>outln
  \ outln() { printf %s\\n "$@"; }
inoremap <unique> <buffer> <LocalLeader>err
  \ err() { printf %s "$@" >&2; }
inoremap <unique> <buffer> <LocalLeader>errln
  \ errln() { printf %s\\n "$@" >&2; }
imap <LocalLeader>die
  \ <C-o>:if ! search('\m^ *errln() *{', 'bnw')<CR>
  \  execute "normal i<LocalLeader>errln\n"<CR>
  \endif<CR>
  \<C-o>:if ! search('\m^ *name="\$( basename', 'bnw')<CR>
  \  execute "normal i<LocalLeader>name\n"<CR>
  \endif<CR>
  \<C-o>:setlocal paste<CR>
  \die() { c="$1"; errln "$2: '${name}' -- $3"; shift 3; errln "$@"
  \; exit "$c"; }<CR>
  \<C-o>:setlocal nopaste<CR>

" Much thanks to Rich (https://www.etalabs.net/sh_tricks.html for eval_escape)
" Keeping to the analogy, this is ruby's p, but not really, so renamed
inoremap <unique> <buffer> <LocalLeader>escape
  \ eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
inoremap <unique> <buffer> <LocalLeader>awk_eval
  \ awk_evalescape='<CR>
  \   function evalEscape(target) {<CR>
  \     gsub(/'\''/, "'\'\\\\\'\''", target);<CR>
  \     #return target<CR>
  \     return "'\''" target "'\''"<CR>
  \   }<CR>
  \ '

inoremap <unique> <buffer> <LocalLeader>match
  \ <C-o>:setlocal paste<CR>
  \match_any() {<CR>
  \  matchee="$1"; shift 1<CR>
  \  [ -z "${matchee}" ] && return 1<CR>
  \  for matcher in "$@"; do  # Literal match in case<CR>
  \    case "${matchee}" in "${matcher}") return 0 ;; esac<CR>
  \  done<CR>
  \  return 1<CR>
  \}
  \<C-o>:setlocal nopaste<CR>

inoremap <unique> <buffer> <LocalLeader>abs
  \ <C-o>:setlocal paste<CR>
  \absolute_path() (<CR>
  \  dir="$( dirname "${1}"; printf a )"; dir="${dir%?a}"<CR>
  \  cd "${dir}" <bar><bar> exit "$?"<CR>
  \  wdir="$( pwd -P; printf a )"; wdir="${wdir%?a}"<CR>
  \  base="$( basename "${1}"; printf a )"; base="${base%?a}"<CR>
  \  output="${wdir}/${base}"<CR>
  \  [ "${output}" = "///" ] && output="/"<CR>
  \  printf %s "${output%/.}"<CR>
  \)
  \<C-o>:setlocal nopaste<CR>




imap <unique> <buffer> <LocalLeader>help
  \ <C-o>:if ! search('\m^name="\$( basename "\$0"', 'bnw')<CR>
  \  execute "normal i<LocalLeader>name\n\n"<CR>
  \endif<CR>
  \<C-o>:setlocal paste<CR>
  \show_help() {<CR>
  \  <<EOF cat - >&2<CR>
  \SYNOPSIS<CR>
  \  ${name}<CR>
  \<CR>
  \DESCRIPTION<CR>
  \  <CR>
  \<CR>
  \OPTIONS<CR>
  \  --<CR>
  \    Special argument that prevents all following arguments from being<CR>
  \    intepreted as options.<CR>
  \EOF<CR>
  \}
  \<C-o>:setlocal nopaste<CR>


" Program setup inspired by C
" Different levels of complication for main
imap <unique> <buffer> <LocalLeader>main1
  \ <C-o>:setlocal paste<CR>
  \main() {<CR>
  \  # Dependencies<CR>
  \<CR>
  \  # Options processing<CR>
  \  args=''; literal='false'<CR>
  \  for arg in "$@"; do<CR>
  \    "${literal}" <Bar><Bar> case "${arg}" in<CR>
  \      --)  literal='true' ;;<CR>
  \      -h<Bar>--help)  show_help; exit 0 ;;<CR>
  \      *)   args="${args} $( outln "${arg}" <Bar> eval_escape )" ;;<CR>
  \    esac<CR>
  \    "${literal}" && args="${args} $( outln "${arg}" <Bar> eval_escape )"<CR>
  \  done<CR>
  \<CR>
  \  [ -z "${args}" ] && { show_help; exit 1; }<CR>
  \  eval "set -- ${args}"<CR>
  \<CR>
  \}
  \<C-o>:setlocal nopaste<CR>

imap <unique> <buffer> <LocalLeader>main2
  \ <C-o>:setlocal paste<CR>
  \# Handles options that need arguments<CR>
  \main() {<CR>
  \  # Dependencies<CR>
  \<CR>
  \  # Options processing<CR>
  \  args=''<CR>
  \  literal='false'<CR>
  \  while [ "$#" -gt 0 ]; do<CR>
  \    "${literal}" <Bar><Bar> case "$1" in<CR>
  \      --)  literal='true'; shift 1; continue ;;<CR>
  \      -h<Bar>--help)  show_help; exit 0 ;;<CR>
  \<CR>
  \      -f)  echo 'do not need to shift' ;;<CR>
  \      -e<Bar>--example2)  outln "-$2-"; shift 1 ;;<CR>
  \<CR>
  \      *)   args="${args} $( outln "$1" <Bar> eval_escape )" ;;<CR>
  \    esac<CR>
  \    "${literal}" && args="${args} $( outln "$1" <Bar> eval_escape )"<CR>
  \    shift 1<CR>
  \  done<CR>
  \<CR>
  \  [ -z "${args}" ] && { show_help; exit 1; }<CR>
  \  eval "set -- ${args}"<CR>
  \<CR>
  \}
  \<C-o>:setlocal nopaste<CR>

imap <unique> <buffer> <LocalLeader>main3
  \ <C-o>:setlocal paste<CR>
  \# Handles single character-options joining (eg. pacman -Syu)<CR>
  \main() {<CR>
  \  # Flags<CR>
  \<CR>
  \  # Dependencies<CR>
  \<CR>
  \  # Options processing<CR>
  \  args=''<CR>
  \  literal='false'<CR>
  \  while [ "$#" -gt 0 ]; do<CR>
  \    if ! "${literal}"; then<CR>
  \      # Split grouped single-character arguments up, and interpret '--'<CR>
  \      # Parsing '--' here allows "invalid option -- '-'" error later<CR>
  \      case "$1" in<CR>
  \        --)      literal='true'; shift 1; continue ;;<CR>
  \        -[!-]*)  opts="$( outln "${1#-}" <Bar>
  \ sed 's/./ -&/g' )" ;;<CR>
  \        --?*)    opts="$1" ;;<CR>
  \        *)       opts="regular" ;;  # Any non-hyphen value will do<CR>
  \      esac<CR>
  \<CR>
  \      # Process arguments properly now<CR>
  \      for x in ${opts}; do case "$x" in<CR>
  \        -h<Bar>--help)  show_help; exit 0 ;;<CR>
  \        -e<Bar>--example)  outln "-$2-"; shift 1 ;;<CR>
  \<CR>
  \        # Put argument checks above this line (for error detection)<CR>
  \        # first '--' case already covered by first case statement<CR>
  \        -[!-]*)   show_help; die 1 FATAL "invalid option '${x#-}'" ;;<CR>
  \        *)        args="${args} $( outln "$1" <Bar> eval_escape )" ;;<CR>
  \      esac done<CR>
  \    else<CR>
  \      args="${args} $( outln "$1" <bar> eval_escape )"<CR>
  \    fi<CR>
  \    shift 1<CR>
  \  done<CR>
  \<CR>
  \  [ -z "${args}" ] && { show_help; exit 1; }<CR>
  \  eval "set -- ${args}"<CR>
  \<CR>
  \}
  \<C-o>:setlocal nopaste<CR>

" Interactive menu main
imap <unique> <buffer> <LocalLeader>mainm
  \ <C-o>:setlocal paste<CR>
  \RED='\001\033[31m\002'<CR>
  \GREEN='\001\033[32m\002'<CR>
  \YELLOW='\001\033[33m\002'<CR>
  \BLUE='\001\033[34m\002'<CR>
  \MAGENTA='\001\033[35m\002'<CR>
  \CYAN='\001\033[36m\002'<CR>
  \CLEAR='\001\033[0m\002'<CR>
  \<CR>
  \main() {<CR>
  \  [ "$#" = 0 ] && eval "set -- $( prompt '.*' "$( outln \<CR>
  \    "${CYAN}help${CLEAR}" \<CR>
  \    "${CYAN}example${CLEAR} <arg> [<arg2>]" \<CR>
  \    "${CYAN}example2${CLEAR} <dir> <arg2> ..." \<CR>
  \    "Enter one of the options: ${CYAN}" \<CR>
  \  )" )"<CR>
  \  cmd="${1}"; shift 1<CR>
  \  case "${cmd}" in<CR>
  \    h*)  show_help; exit 0 ;;<CR>
  \<CR>
  \    e*)  echo 1 ;;<CR>
  \    2)   echo 2 ;;<CR>
  \<CR>
  \    *)   show_help; exit 1 ;;<CR>
  \  esac<CR>
  \}
  \<C-o>:setlocal nopaste<CR>

imap <unique> <buffer> <LocalLeader>init
  \ <LocalLeader>sbsh<CR>
  \<CR>
  \<LocalLeader>name<CR>
  \<CR>
  \<LocalLeader>help<CR>
  \<CR><CR><CR>
  \<LocalLeader>main3<CR>
  \<CR><CR><CR>
  \# Helpers<CR>
  \<LocalLeader>outln<CR>
  \<LocalLeader>errln<CR>
  \<LocalLeader>die<CR>
  \<LocalLeader>escape<CR>
  \<CR>
  \main "$@"<Esc>
