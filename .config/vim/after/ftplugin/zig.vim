let s:run_line = '//run:\(.*\)'

function! s:BuildBackground() abort
endfunction

function! s:Build() abort
  " `%` is the full path, `expand("%")` is just the current file name
  "execute("vertical T rustc % -o \"${TMPDIR}/" . expand("%") . '"')
  vertical T zig build
  execute "normal! \<C-w>\<C-w>"
  normal! G
  execute "normal! \<C-w>\<C-w>"
endfunction

function! s:Run() abort
  " `%` is the full path, `expand("%")` is just the current file name
  "execute("vertical T rustc % -o \"${TMPDIR}/" . expand("%") . '"')
  vertical T zig build test
  execute "normal! \<C-w>\<C-w>"
  normal! G
  execute "normal! \<C-w>\<C-w>"
endfunction

function! s:Lint() abort
endfunction

let b:BuildBackground = function('<SID>BuildBackground')
let b:Build = function('<SID>Build')
let b:Run = function('<SID>Run')
"let b:Run = function('CustomisableMake', [s:run_line, 'run', ''])
let b:Lint = function('<SID>Lint')
