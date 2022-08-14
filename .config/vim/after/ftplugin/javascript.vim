let s:run_line = '//run:\(.*\)'

function! s:Lint() abort
endfunction


let b:BuildBackground = function('Make', [0, 'build', ''])
let b:Build = function('CustomisableMake', [s:run_line, 'build', ''])
let b:Run = function('CustomisableMake', [s:run_line, 'run', ''])
let b:Lint = function('<SID>Lint')
