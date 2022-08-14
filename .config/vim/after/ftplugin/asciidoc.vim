function! s:Run() abort
  " Probably should use the output of `compile.sh`
  let l:path = $TMPDIR . "/" . expand('%:t:r') . ".html"
  if !filereadable(l:path)
    call b:Build()
  endif
  " Do not want necessarily need setsid
  " `falkon` has live reload
  call system('falkon --private-browsing --no-extensions --new-window '
    \ . shellescape(l:path) . ' >/dev/null 2>&1&')
endfunction

"function! Lint()
"endfunction

let b:BuildBackground = function('Make', [0, 'build', '--temp'])
let b:Build = function('Make', [1, 'build', '--temp'])
let b:Run = function('<SID>Run')
