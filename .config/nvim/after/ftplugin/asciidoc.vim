function! Build()
  write
  vertical T compile.sh --temp %
endfunction

function! BuildBackground()
  write
  compile.sh --temp %
endfunction

function! Run()
  " Probably should use the output of `compile.sh`
  let l:path = $TMPDIR . "/" . expand('%:t:r')
  if filereadable(l:path)
    call Build()
  endif
  " Do not want necessarily need setsid
  " `falkon` has live reload
  call system('falkon --private-browsing --no-extensions "'
    \ . l:path . '.html" >/dev/null 2>&1&')
endfunction


"function! Lint()
"endfunction
