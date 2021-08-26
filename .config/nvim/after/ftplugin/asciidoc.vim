function! s:Build() abort
  write
  vertical T compile.sh --temp %
endfunction

function! s:BuildBackground() abort
  write
  silent !compile.sh --temp %
endfunction

function! s:Run() abort
  " Probably should use the output of `compile.sh`
  let l:path = $TMPDIR . "/" . expand('%:t:r') . ".html"
  if !filereadable(l:path)
    call s:Build()
  endif
  " Do not want necessarily need setsid
  " `falkon` has live reload
  call system('falkon --private-browsing --no-extensions --new-window '
    \ . shellescape(l:path) . ' >/dev/null 2>&1&')
endfunction

"function! Lint()
"endfunction

let b:Build = function('<SID>Build')
let b:BuildBackground = function('<SID>BuildBackground')
let b:Run = function('<SID>Run')
