augroup shellbuild
  " Use sh (usually maps to dash terminal) for better POSIX compliance
  autocmd FileType sh noremap <silent> <leader>2 :call BuildAndRun($TMPDIR . '/preview', 'chmod 755 ' . $TMPDIR . '/preview', $TMPDIR . '/preview')<CR>
  "autocmd FileType sh noremap <silent> <leader>3 :call PreviewOpen($TERMINAL . ' -e')<CR>
  "autocmd FileType sh noremap <silent> <leader>4 :call PreviewClose()<CR>
  "autocmd FileType sh noremap <silent> <leader>l :call PreviewSendLine('shellcheck ' . expand('%:p'))<CR>
  autocmd FileType sh noremap <silent> <leader>l :call Lint()<CR>
augroup END

function! Lint()
  !clear && online-shellcheck.sh -i %
  "if command -v shellcheck >/dev/null >&2; then 
endfunction

"function! Build()
"endfunction
"function! Run()
"endfunction
