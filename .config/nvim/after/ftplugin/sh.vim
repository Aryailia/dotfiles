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
  vertical T sh %
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
