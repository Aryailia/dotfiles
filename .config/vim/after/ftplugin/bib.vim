set suffixesadd=.pdf,.epub,.mobi

function! s:Lint() abort
  execute('vertical T build.sh lint ' . shellescape(expand('%:p')))
endfunction

let b:Lint = function('<SID>Lint')
