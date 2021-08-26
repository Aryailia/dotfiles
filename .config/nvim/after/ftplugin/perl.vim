let s:cmdline_prefix_regexp = '#run:'

function! s:BuildBackground() abort
  write
  let b:build_background = 1
  call RunCmdlineOverload(s:cmdline_prefix_regexp,
    \ function('s:RunDefault'), function('s:RunWithArguments'))
endfunction

function! s:Build() abort
  write
  let b:build_background = 0
  call RunCmdlineOverload(s:cmdline_prefix_regexp,
    \ function('s:RunDefault'), function('s:RunWithArguments'))
endfunction

function! s:Run() abort
  call s:Build()
endfunction

function! s:RunDefault() abort
  if b:build_background
    " Taint-mode, environments variables must verified before use
    silent !perl -T %
  else
    vertical T perl -T %
  endif
endfunction

function! s:RunWithArguments(cmdline) abort
  if b:build_background
    execute 'silent !' . a:cmdline
  else
    execute('vertical T ' . a:cmdline)
  endif
endfunction

"function! Lint()
"endfunction

let b:Build = function('<SID>Build')
let b:BuildBackground = function('<SID>BuildBackground')
let b:Run = function('<SID>Run')
