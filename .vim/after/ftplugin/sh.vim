" Use sh (usually maps to dash terminal) for better POSIX compliance
"noremap <silent> <leader>2 :call BuildAndRun($TMPDIR . '/preview', 'chmod 755 ' . $TMPDIR . '/preview', $TMPDIR . '/preview')<CR>
"noremap <silent> <leader>3 :call PreviewOpen($TERMINAL . ' -e')<CR>
"noremap <silent> <leader>4 :call PreviewClose()<CR>
"noremap <silent> <leader>l :call PreviewSendLine('shellcheck ' . expand('%:p'))<CR>

function! Lint()
  "!clear && online-shellcheck.sh -i %
  "if command -v shellcheck >/dev/null >&2; then 
  vertical T online-shellcheck.sh -i %
endfunction

function! Run()
  clear 
endfunction
"function! Build()
"endfunction


" Snippets

" Thanks to Rich (https://www.etalabs.net/sh_tricks.html for eval_escape)
inoremap <buffer> <LocalLeader>die
  \ die() { exitcode="$1"; shift 1; printf %s\\n "$@" >&2
  \; exit "${exitcode}"; }<CR>
inoremap <buffer> <LocalLeader>req
  \ require() { command -v "$1" >/dev/null 2>&1; }<CR>

" Naming modeled after the print commands in ruby
inoremap <buffer> <LocalLeader>puts
  \ puts() { printf %s\\n "$@"; }<CR>
inoremap <buffer> <LocalLeader>prints
  \ prints() { printf %s "$@"; }<CR>
" Keeping to the analogy, this is ruby's p, but not really, so renamed
inoremap <buffer> <LocalLeader>eval
  \ eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }<CR>
inoremap <buffer> <LocalLeader>pute
  \ puterr() { printf %s\\n "$@" >&2; }<CR>
inoremap <buffer> <LocalLeader>printe
  \ printerr() { printf %s "$@" >&2; }<CR>


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
  \}<CR>
  \<C-o>:set nopaste<CR>
