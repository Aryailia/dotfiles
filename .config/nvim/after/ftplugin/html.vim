function s:Run() abort
  silent !falkon --private-browsing --no-extensions --new-window
    \ "%" >/dev/null 2>&1&
endfunction

let b:Run = function('<SID>Run')
