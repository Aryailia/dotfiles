let s:cmdline_prefix_regexp = '//run:'
set suffixesadd=.java

function! s:BuildBackground() abort
  write
  call RunCmdlineOverload('#run: ',
    \ function('s:RunDefault'), function('s:RunWithArguments'))
endfunction

function! s:Build() abort
  vertical T build.sh build %
  write
endfunction

function! s:Run() abort
  call RunCmdlineOverload(s:cmdline_prefix_regexp,
    \ function('s:RunDefault'), function('s:RunWithArguments'))
endfunction

function! s:RunDefault() abort
  vertical T build.sh buildrun %
endfunction

function! s:RunWithArguments(cmdline) abort
  execute('vertical T ' . a:cmdline)
endfunction

"function! Lint() abort
"endfunction

let b:Build = function('<SID>Build')
let b:BuildBackground = function('<SID>BuildBackground')
let b:Run = function('<SID>Run')
