let s:run_line = '#run:\(.*\)'

"function! Lint()
"endfunction

let b:BuildBackground = function('Make', [0, 'build', ''])
" TODO: No way to use taint mode for `b:Build` default with new system
let b:Build = function('Make', [1, 'build', ''])
let b:Run = function('CustomisableMake', [s:run_line, 'build', ''])
