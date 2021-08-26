" Use sh (usually maps to dash terminal) for better POSIX compliance
"noremap <silent> <leader>2 :call BuildAndRun($TMPDIR . '/preview', 'chmod 755 ' . $TMPDIR . '/preview', $TMPDIR . '/preview')<CR>
"noremap <silent> <leader>3 :call PreviewOpen($TERMINAL . ' -e')<CR>
"noremap <silent> <leader>4 :call PreviewClose()<CR>
"noremap <silent> <leader>l :call PreviewSendLine('shellcheck ' . expand('%:p'))<CR>

let b:ale_lint_on_text_changed = 'never'
let b:ale_lint_on_insert_leave = 0
let b:ale_lint_on_save = 1
let b:ale_lint_on_enter = 0

function! s:BuildBackground() abort
  write
  let b:build_background = 1
  call RunCmdlineOverload('#run: ',
    \ function('s:RunDefault'), function('s:RunWithArguments'))
endfunction

function! s:Build() abort
  write
  let b:build_background = 0
  call RunCmdlineOverload('#run: ',
    \ function('s:RunDefault'), function('s:RunWithArguments'))
endfunction

function! s:Run() abort
  call s:Build()
endfunction

function! s:RunDefault() abort
  if b:build_background
    silent !sh %
  else
    vertical T sh %
  endif
endfunction

function! s:RunWithArguments(cmdline) abort
  if b:build_background
    execute 'silent !' . a:cmdline
  else
    execute('vertical T ' . a:cmdline)
  endif
endfunction

function! s:Lint() abort
  vertical T shellcheck %
endfunction

let b:Build = function('<SID>Build')
let b:BuildBackground = function('<SID>BuildBackground')
let b:Run = function('<SID>Run')
let b:Lint = function('<SID>Lint')
