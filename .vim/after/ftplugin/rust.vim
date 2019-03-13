function! Build()
  write
  execute("vertical T rustc % -o ${TMPDIR}/" . expand("%"))
endfunction

function! Run()
  execute("T ${TMPDIR}/" . expand("%"))
endfunction

"function! Lint()
"endfunction
