let s:cmdline_prefix_regexp = '//run:\(.*\)'
set suffixesadd=.java

function! s:BuildBackground() abort
  write
  call RunCmdlineOverload('#run: ',
    \ function('b:Build'), function('s:RunWithArguments'))
endfunction

function! s:Run() abort
  call RunCmdlineOverload(s:cmdline_prefix_regexp,
    \ function('Make', ['buildrun', '']), function('s:RunWithArguments'))
endfunction

function! s:RunWithArguments(cmdline) abort
  execute('vertical T ' . a:cmdline)
endfunction

"function! Lint() abort
"endfunction

let b:Build = function('Make', ['build', ''])
let b:BuildBackground = function('<SID>BuildBackground')
let b:Run = function('<SID>Run')
