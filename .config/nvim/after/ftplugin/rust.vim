let s:cmdline_prefix_regexp = '//run:'

function! s:BuildBackground() abort
  vertical T cargo check
endfunction

function! s:Build() abort
  " `%` is the full path, `expand("%")` is just the current file name
  "execute("vertical T rustc % -o \"${TMPDIR}/" . expand("%") . '"')
  vertical T cargo build
  execute "normal! \<C-w>\<C-w>"
  normal! G
  execute "normal! \<C-w>\<C-w>"
endfunction

function! s:Run() abort
  call RunCmdlineOverload(s:cmdline_prefix_regexp,
    \function('s:RunDefault'), function('s:RunWithArguments'))
endfunction

function! s:RunDefault() abort
  vertical T cargo run
endfunction

function! s:RunWithArguments(cmdline) abort
  execute('vertical T ' . a:cmdline)
endfunction

function! s:Lint() abort
  RustFmt
  vertical T cargo clippy
endfunction

let b:Build = function('<SID>Build')
let b:BuildBackground = function('<SID>BuildBackground')
let b:Run = function('<SID>Run')
let b:Lint = function('<SID>Lint')
