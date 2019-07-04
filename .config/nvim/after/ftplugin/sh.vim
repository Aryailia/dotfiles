" Use sh (usually maps to dash terminal) for better POSIX compliance
"noremap <silent> <leader>2 :call BuildAndRun($TMPDIR . '/preview', 'chmod 755 ' . $TMPDIR . '/preview', $TMPDIR . '/preview')<CR>
"noremap <silent> <leader>3 :call PreviewOpen($TERMINAL . ' -e')<CR>
"noremap <silent> <leader>4 :call PreviewClose()<CR>
"noremap <silent> <leader>l :call PreviewSendLine('shellcheck ' . expand('%:p'))<CR>

function! Lint()
  "!clear && online-shellcheck.sh -i %
  vertical T if shellcheck -V >/dev/null 2>&1;
    \  then shellcheck %;
    \  else online-shellcheck.sh -i %;
    \fi
endfunction

function! Run()
  vertical T sh -c %
endfunction
function! Build()
  write
  vertical T sh -c %
endfunction


" Snippets
inoremap <buffer> <LocalLeader>sbsh
  \ #!/usr/bin/env sh
inoremap <buffer> <LocalLeader>sbawk
  \ #!/usr/bin/awk -f
inoremap <buffer> <LocalLeader>sbpython
  \ #!/usr/bin/env python

inoremap <buffer> <LocalLeader>name
  \ name="$( basename "$0"; printf a )"; name="${name%?a}"
inoremap <buffer> <LocalLeader>puts
  \ puts() { printf %s\\n "$@"; }
imap <LocalLeader>die
  \ <C-o>:if ! search('\m^puts() *{', 'bnw')<CR>
  \  execute "normal i,puts\n"<CR>
  \endif<CR>
  \<C-o>:if ! search('\m^name="\$( basename', 'bnw')<CR>
  \  execute "normal i,name\n"<CR>
  \endif<CR>
  \<C-o>:setlocal paste<CR>
  \die() {<CR>
  \  c="$1"; puts "$2: '${name}' -- $3" >&2; shift 3<CR>
  \  puts "$@" >&2; exit "$c"<CR>
  \}
  \<C-o>:setlocal nopaste<CR>
imap <LocalLeader>asdf
  \ <C-o>:if ! search('\m^ *puts() *{', 'bnw')<CR>
  \  execute "normal i,puts\n"<CR>
  \endif<CR>
  \die() {<CR>
  \  c="$1"; puts "$2: '${name}' -- $3" >&2; shift 3<CR>
  \  puts "$@" >&2; exit "$c"<CR>
  \}
  \<C-o>:setlocal nopaste<CR>

" Neither `which` nor `command -v` are defined in POSIX
" Some systems do not have `which` or it does not error code
" For some shells (like 'dash') `command -v` works more like `test -e`
inoremap <buffer> <LocalLeader>req
  \ <C-o>:setlocal paste<CR>
  \require() {<CR>
  \  for dir in $( printf %s "${PATH}" <Bar> tr ':' '\n' ); do<CR>
  \    [ -f "${dir}/$1" ] && [ -x "${dir}/$1" ] && return 0<CR>
  \  done<CR>
  \  return 1<CR>
  \}
  \<C-o>:setlocal nopaste<CR>


" Defends against malicious $2 but not malicious $1. $1 must be valid varname
inoremap <buffer> <LocalLeader>assign
  \ eval_assign() { eval "$1"=\"$2\"; }

" Naming modeled after the print commands in ruby
inoremap <buffer> <LocalLeader>puts
  \ puts() { printf %s\\n "$@"; }
inoremap <buffer> <LocalLeader>prints
  \ prints() { printf %s "$@"; }
" Much thanks to Rich (https://www.etalabs.net/sh_tricks.html for eval_escape)
" Keeping to the analogy, this is ruby's p, but not really, so renamed
inoremap <buffer> <LocalLeader>escape
  \ eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
inoremap <buffer> <LocalLeader>pute
  \ puterr() { printf %s\\n "$@" >&2; }
inoremap <buffer> <LocalLeader>printe
  \ printerr() { printf %s "$@" >&2; }

inorema <buffer> <LocalLeader>match
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




imap <buffer> <LocalLeader>help
  \ <LocalLeader>name<CR>
  \<C-o>:setlocal paste<CR>
  \<CR>
  \show_help() {<CR>
  \  <<EOF cat - >&2<CR>
  \SYNOPSIS<CR>
  \  ${name}<CR>
  \<CR>
  \DESCRIPTION<CR>
  \  <CR>
  \EOF<CR>
  \}
  \<C-o>:setlocal nopaste<CR>


" Program setup inspired by C
" Different levels of complication for main
imap <buffer> <LocalLeader>main1
  \ <C-o>:setlocal paste<CR>
  \main() {<CR>
  \  # Dependencies<CR>
  \<CR>
  \  # Options processing<CR>
  \  args=''; no_options='false'<CR>
  \  for arg in "$@"; do "${no_options}" <Bar><Bar> case "${arg}" in<CR>
  \    --)  no_options='true' ;;<CR>
  \    -h<Bar>--help)  show_help; exit 0 ;;<CR>
  \    *)   args="${args} $( puts "${arg}" <Bar> eval_escape )" ;;<CR>
  \  esac done<CR>
  \<CR>
  \  [ -z "${args}" ] && { show_help; exit 1; }<CR>
  \  eval "set -- ${args}"<CR>
  \<CR>
  \}
  \<C-o>:setlocal nopaste<CR>

imap <buffer> <LocalLeader>main2
  \ <C-o>:setlocal paste<CR>
  \# Handles options that need arguments<CR>
  \main() {<CR>
  \  # Dependencies<CR>
  \<CR>
  \  # Options processing<CR>
  \  args=''<CR>
  \  no_options='false'<CR>
  \  while [ "$#" -gt 0 ]; do<CR>
  \    "${no_options}" <Bar><Bar> case "$1" in<CR>
  \      --)  no_options='true'; shift 1; continue ;;<CR>
  \      -h<Bar>--help)  show_help; exit 0 ;;<CR>
  \<CR>
  \      -f)  echo 'do not need to shift' ;;<CR>
  \      -e<Bar>--example2)  puts "-$2-"; shift 1 ;;<CR>
  \<CR>
  \      *)   args="${args} $( puts "$1" <Bar> eval_escape )" ;;<CR>
  \    esac<CR>
  \    "${no_options}" && args="${args} $( puts "$1" <Bar> eval_escape )"<CR>
  \    shift 1<CR>
  \  done<CR>
  \<CR>
  \  [ -z "${args}" ] && { show_help; exit 1; }<CR>
  \  eval "set -- ${args}"<CR>
  \<CR>
  \}
  \<C-o>:setlocal nopaste<CR>

imap <buffer> <LocalLeader>main3
  \ <C-o>:setlocal paste<CR>
  \# Handles single character-options joining (eg. pacman -Syu)<CR>
  \main() {<CR>
  \  # Flags<CR>
  \<CR>
  \  # Dependencies<CR>
  \<CR>
  \  # Options processing<CR>
  \  args=''<CR>
  \  no_options='false'<CR>
  \  while [ "$#" -gt 0 ]; do<CR>
  \    if ! "${no_options}"; then<CR>
  \      # Split grouped single-character arguments up, and interpret '--'<CR>
  \      # Parsing '--' here allows "invalid option -- '-'" error later<CR>
  \      opts=''<CR>
  \      case "$1" in<CR>
  \        --)      no_options='true'; shift 1; continue ;;<CR>
  \        -[!-]*)  opts="${opts}$( puts "${1#-}" <Bar> sed 's/./ -&/g' )" ;;<CR>
  \        *)       opts="${opts} $1" ;;<CR>
  \      esac<CR>
  \<CR>
  \      # Process arguments properly now<CR>
  \      for x in ${opts}; do case "${x}" in<CR>
  \        -h<Bar>--help)  show_help; exit 0 ;;<CR>
  \        -e<Bar>--example)  puts "-$2-"; shift 1 ;;<CR>
  \<CR>
  \        # Put argument checks above this line (for error detection)<CR>
  \        # first '--' case already covered by first case statement<CR>
  \        -[!-]*)   show_help; die 1 "FATAL: invalid option '${x#-}'" ;;<CR>
  \        *)        args="${args} $( puts "$1" <Bar> eval_escape )" ;;<CR>
  \      esac done<CR>
  \    else<CR>
  \      args="${args} $( puts "$1" <bar> eval_escape )"<CR>
  \    fi<CR>
  \    shift 1<CR>
  \  done<CR>
  \<CR>
  \  [ -z "${args}" ] && { show_help; exit 1; }<CR>
  \  eval "set -- ${args}"<CR>
  \<CR>
  \}
  \<C-o>:setlocal nopaste<CR>

imap <buffer> <LocalLeader>init
  \ <LocalLeader>sbsh<CR>
  \<CR>
  \<LocalLeader>help<CR>
  \<CR><CR><CR>
  \<LocalLeader>main3<CR>
  \<CR><CR><CR>
  \# Helpers<CR>
  \<LocalLeader>puts<CR>
  \<LocalLeader>die<CR>
  \<LocalLeader>escape<CR>
  \<CR>
  \main "$@"<Esc>
