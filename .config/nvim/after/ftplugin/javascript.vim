let s:cmdline_prefix_regexp = '//run:'

function! BuildBackground()
  call RunCmdlineOverload(s:cmdline_prefix_regexp,
    \function('s:BackgroundDefault'), function('s:BackgroundWithArguments'))
endfunction

function! s:BackgroundDefault()
  silent !node %
endfunction

function! s:BackgroundWithArguments(cmdline)
  call system(a:cmdline)
endfunction

function! Build()
  " `%` is the full path, `expand("%")` is just the current file name
  "execute("vertical T rustc % -o \"${TMPDIR}/" . expand("%") . '"')
  vertical T node %
  execute "normal! \<C-w>\<C-w>"
  normal! G
  execute "normal! \<C-w>\<C-w>"
endfunction

function! s:RunDefault()
  vertical T node %
endfunction

function! s:RunWithArguments(cmdline)
  execute('vertical T ' . a:cmdline)
endfunction

function! Run()
  call RunCmdlineOverload(s:cmdline_prefix_regexp,
    \function('s:RunDefault'), function('s:RunWithArguments'))
endfunction

function! Lint()
endfunction
