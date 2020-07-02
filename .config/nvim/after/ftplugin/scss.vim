let s:cmdline_prefix_regexp = '//run:'

function! Build()
  write
  execute('vertical T sassc ' . expand('%:S') . ' >' . expand('%:r:S') . '.css')
endfunction

function! s:RunDefault()
endfunction

function! s:RunWithArguments(cmdline)
endfunction

function! Run()
  write
  "call RunCmdlineOverload(s:cmdline_prefix_regexp,
  "  \function('s:RunDefault'), function('s:RunWithArguments'))
endfunction

function! Lint()
endfunction
