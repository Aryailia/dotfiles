function! Build()
  write
  " `%` is the full path, `expand("%")` is just the current file name
  execute("vertical T rustc % -o \"${TMPDIR}/" . expand("%") . '"')
endfunction

function! Run()
  execute("vertical T \"${TMPDIR}/" . expand("%") . '"')
endfunction

"function! Lint()
"endfunction
