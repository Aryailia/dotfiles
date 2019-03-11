" Use sh (usually maps to dash terminal) for better POSIX compliance
"noremap <silent> <leader>2 :call BuildAndRun($TMPDIR . '/preview', 'chmod 755 ' . $TMPDIR . '/preview', $TMPDIR . '/preview')<CR>
"noremap <silent> <leader>3 :call PreviewOpen($TERMINAL . ' -e')<CR>
"noremap <silent> <leader>4 :call PreviewClose()<CR>
"noremap <silent> <leader>l :call PreviewSendLine('shellcheck ' . expand('%:p'))<CR>
noremap <silent> <leader>l :call Lint()<CR>

function! Lint()
  !clear && online-shellcheck.sh -i %
  "if command -v shellcheck >/dev/null >&2; then 
endfunction

"function! Build()
"endfunction
"function! Run()
"endfunction


" Snippets

" Thanks to Rich (https://www.etalabs.net/sh_tricks.html for eval_escape)
inoremap <buffer> <leader>die
  \ die() { exitcode="$1"; shift 1; printf %s\\n "$@" >&2
  \; exit "${exitcode}"; }<CR>

" Naming modeled after the print commands in ruby
inoremap <buffer> <leader>puts
  \ puts() { printf %s\\n "$@"; }<CR>
inoremap <buffer> <leader>prints
  \ prints() { printf %s "$@"; }<CR>
" Keeping to the analogy, this is ruby's p, but not really, so renamed
inoremap <buffer> <leader>eval
  \ eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }<CR>
inoremap <buffer> <leader>pute
  \ puterr() { printf %s\\n "$@" >&2; }<CR>
inoremap <buffer> <leader>printe
  \ printerr() { printf %s "$@" >&2; }<CR>


inoremap <buffer> <leader>help <C-o>:set paste<CR>
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
