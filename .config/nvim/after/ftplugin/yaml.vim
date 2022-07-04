function! s:Lint() abort
  vertical T yq-go eval %
endfunction

let b:Lint = function('<SID>Lint')
