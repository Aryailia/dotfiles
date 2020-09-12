let s:cmdline_prefix_regexp = '//run:'

function! BuildBackground()
  vertical T cargo check
endfunction

function! Build()
  " `%` is the full path, `expand("%")` is just the current file name
  "execute("vertical T rustc % -o \"${TMPDIR}/" . expand("%") . '"')
  vertical T cargo build
  execute "normal! \<C-w>\<C-w>"
  normal! G
  execute "normal! \<C-w>\<C-w>"
endfunction

function! s:RunDefault()
  vertical T cargo run
endfunction

function! s:RunWithArguments(cmdline)
  execute('vertical T ' . a:cmdline)
endfunction

function! Run()
  call RunCmdlineOverload(s:cmdline_prefix_regexp,
    \function('s:RunDefault'), function('s:RunWithArguments'))
endfunction

function! Lint()
  RustFmt
  ALELint
endfunction
