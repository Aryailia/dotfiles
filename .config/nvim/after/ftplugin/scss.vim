let s:cmdline_prefix_regexp = '//run:'

function! s:Build() abort
  write
  execute('vertical T sassc ' . expand('%:S') . ' >' . expand('%:r:S') . '.css')
endfunction

function! s:Run() abort
  write
  "call RunCmdlineOverload(s:cmdline_prefix_regexp,
  "  \function('s:RunDefault'), function('s:RunWithArguments'))
endfunction

"function! s:RunDefault()
"endfunction
"
"function! s:RunWithArguments(cmdline)
"endfunction

"function! s:Lint()
"endfunction

let b:Build = function('<SID>Build')
let b:Run = function('<SID>Run')
