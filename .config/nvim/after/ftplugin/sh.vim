" Use sh (usually maps to dash terminal) for better POSIX compliance
"noremap <silent> <leader>2 :call BuildAndRun($TMPDIR . '/preview', 'chmod 755 ' . $TMPDIR . '/preview', $TMPDIR . '/preview')<CR>
"noremap <silent> <leader>3 :call PreviewOpen($TERMINAL . ' -e')<CR>
"noremap <silent> <leader>4 :call PreviewClose()<CR>
"noremap <silent> <leader>l :call PreviewSendLine('shellcheck ' . expand('%:p'))<CR>

function! Lint()
  "!clear && online-shellcheck.sh -i %
  vertical T if command -v shellcheck >/dev/null 2>&1;
    \   then shellcheck %;
    \   else online-shellcheck.sh -i %;
    \ fi
endfunction

function! Run()
  vertical T sh -c %
endfunction
function! Build()
  write
  vertical T sh -c %
endfunction


" Snippets

" Thanks to Rich (https://www.etalabs.net/sh_tricks.html for eval_escape)
inoremap <buffer> <LocalLeader>die
  \ die() { exitcode="$1"; shift 1; printf %s\\n "$@" >&2
  \; exit "${exitcode}"; }
inoremap <buffer> <LocalLeader>req
  \ require() { command -v "$1" >/dev/null 2>&1; }

" Defends against malicious $2 but not malicious $1. $1 must be valid varname
inoremap <buffer> <LocalLeader>dynamic
  \ dynamic_assign() { eval "$1"=\"$2\"; }

" Naming modeled after the print commands in ruby
inoremap <buffer> <LocalLeader>puts
  \ puts() { printf %s\\n "$@"; }
inoremap <buffer> <LocalLeader>prints
  \ prints() { printf %s "$@"; }
" Keeping to the analogy, this is ruby's p, but not really, so renamed
inoremap <buffer> <LocalLeader>eval
  \ eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
inoremap <buffer> <LocalLeader>pute
  \ puterr() { printf %s\\n "$@" >&2; }
inoremap <buffer> <LocalLeader>printe
  \ printerr() { printf %s "$@" >&2; }


inoremap <buffer> <LocalLeader>help <C-o>:set paste<CR>
  \show_help() {<CR>
  \  name="$(basename "$0"; printf a)"; name="${name%??}"<CR>
  \  <<EOF cat - >&2<CR>
  \SYNOPSIS<CR>
  \  ${name}<CR>
  \<CR>
  \DESCRIPTION<CR>
  \  <CR>
  \EOF<CR>
  \}
  \<C-o>:set nopaste<CR>


" Simplist, cannot handle options that need arguments
imap <buffer> <LocalLeader>main1 <C-o>:set paste<CR>
  \main() {<CR>
  \  # Dependencies<CR>
  \<CR>
  \  # Options processing<CR>
  \  args=""; no_options="false"<CR>
  \  for arg in "$@"; do "${no_options}" <Bar><Bar> case "${arg}" in<CR>
  \    --)  no_options="true" ;;<CR>
  \    -h<Bar>--help)  show_help; exit 0 ;;<CR>
  \    *)   args="${args} $(puts "${arg}" <Bar> eval_escape)"<CR>
  \  esac done<CR>
  \<CR>
  \  [ -z "${args}" ] && { show_help; exit 1; }<CR>
  \  eval "set -- ${args}"<CR>
  \<CR>
  \}
  \<C-o>:set nopaste<CR>

" Handles options that need arguments, but cannot handle combined options
imap <buffer> <LocalLeader>main2 <C-o>:set paste<CR>
  \main() {<CR>
  \  # Dependencies<CR>
  \<CR>
  \  # Options processing<CR>
  \  args=""<CR>
  \  no_options="false"<CR>
  \  while [ "$#" -gt 0 ]; do<CR>
  \    "${no_options}" <Bar><Bar> case "$1" in<CR>
  \      --)  no_options="true"; shift 1; continue ;;<CR>
  \      -h<Bar>--help)  show_help; exit 0 ;;<CR>
  \      -e<Bar>--example)  puts "-$2-"; shift 1 ;;
  \      *)   args="${args} $(puts "$1" <Bar> eval_escape)"<CR>
  \    esac<CR>
  \    "${no_options}" && args="${args} $(puts "$1" <Bar> eval_escape)"<CR>
  \    shift 1<CR>
  \  done<CR>
  \<CR>
  \  [ -z "${args}" ] && { show_help; exit 1; }<CR>
  \  eval "set -- ${args}"<CR>
  \<CR>
  \}
  \<C-o>:set nopaste<CR>

" Fullest form, handles combined single-character options (eg. pacman -Syu)
imap <buffer> <LocalLeader>main3 <C-o>:set paste<CR>
  \main() {<CR>
  \  # Flags<CR>
  \<CR>
  \  # Dependencies<CR>
  \<CR>
  \  # Options processing<CR>
  \  args=""<CR>
  \  no_options="false"<CR>
  \  while [ "$#" -gt 0 ]; do<CR>
  \    if ! "${no_options}"; then<CR>
  \      # Split grouped single-character arguments up, and interpret '--'<CR>
  \      # Parsing '--' here allows "invalid option -- '-'" error later<CR>
  \      opts=""<CR>
  \      case "$1" in<CR>
  \        --)      no_options="true"; shift 1; continue ;;<CR>
  \        -[!-]*)  opts="${opts}$(puts "${1#-}" <Bar> sed 's/./ -&/g')" ;;<CR>
  \        *)       opts="${opts} $1" ;;<CR>
  \      esac<CR>
  \<CR>
  \      # Process arguments properly now<CR>
  \      for x in ${opts}; do case "${x}" in<CR>
  \        -h<Bar>--help)  show_help; exit 0 ;;<CR>
  \        -e<Bar>--example)  puts "-$2-"; shift 1 ;;<CR>
  \<CR>
  \        # Put argument checks above this line (for error detection)<CR>
  \        --[!-]*)  show_help; die 1 "FATAL: invalid option '${x#--}'" ;;<CR>
  \        -[!-]*)   show_help; die 1 "FATAL: invalid option '${x#-}'" ;;<CR>
  \        *)        args="${args} $(puts "$1" <Bar> eval_escape)"<CR>
  \      esac done<CR>
  \    else<CR>
  \      args="${args} $(puts "$1" <bar> eval_escape)"<CR>
  \    fi<CR>
  \    shift 1<CR>
  \  done<CR>
  \<CR>
  \  [ -z "${args}" ] && { show_help; exit 1; }<CR>
  \  eval "set -- ${args}"<CR>
  \<CR>
  \}
  \<C-o>:set nopaste<CR>

imap <buffer> <LocalLeader>init
  \ #!/usr/bin/env sh<CR>
  \<CR>
  \<LocalLeader>help<CR>
  \<CR><CR><CR>
  \<LocalLeader>main3<CR>
  \<CR><CR><CR>
  \# Helpers<CR>
  \<LocalLeader>puts<CR>
  \<LocalLeader>die<CR>
  \<LocalLeader>eval<CR>
  \<CR>
  \main "$@"
