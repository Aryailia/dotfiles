function! s:Lint() abort
  vertical T <'%' yq
endfunction

let b:Lint = function('<SID>Lint')
