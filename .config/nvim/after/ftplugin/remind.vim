let s:run_line = '#run:\(.*\)'

function! s:Build() abort
  vertical T <% remind -c+4 -
endfunction


let b:BuildBackground = function('ShellMake', [s:run_line])
let b:Build = function('<SID>Build')
let b:Run = b:BuildBackground
"let b:Lint = function('<SID>Lint')
