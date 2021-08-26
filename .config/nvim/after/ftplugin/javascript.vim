let s:cmdline_prefix_regexp = '//run:'

function! s:BuildBackground() abort
  call RunCmdlineOverload(s:cmdline_prefix_regexp,
    \function('<SID>BuildBackgroundDefault'),
    \function('<SID>BuildBackgroundWithArguments')
  \)
endfunction

function! s:BuildBackgroundDefault() abort
  silent !node %
endfunction

function! s:BuildBackgroundWithArguments(cmdline) abort
  call system(a:cmdline)
endfunction

function! s:Build() abort
  " `%` is the full path, `expand("%")` is just the current file name
  "execute("vertical T rustc % -o \"${TMPDIR}/" . expand("%") . '"')
  vertical T node %
  execute "normal! \<C-w>\<C-w>"
  normal! G
  execute "normal! \<C-w>\<C-w>"
endfunction

function! s:RunDefault() abort
  vertical T node %
endfunction

function! s:RunWithArguments(cmdline) abort
  execute('vertical T ' . a:cmdline)
endfunction

function! s:Run() abort
  call s:RunCmdlineOverload(s:cmdline_prefix_regexp,
    \function('<SID>RunDefault'), function('<SID>RunWithArguments'))
endfunction

function! s:Lint() abort
endfunction


let b:Build = function('<SID>Build')
let b:BuildBackground = function('<SID>BuildBackground')
let b:Run = function('<SID>Run')
let b:Lint = function('<SID>Lint')
