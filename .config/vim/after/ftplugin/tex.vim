let s:run_line = '%run:\(.*\)'

"function! Lint()
"endfunction

let b:BuildBackground = function('Make', [0, 'build', '--temp'])
let b:Build = function('CustomisableMake', [s:run_line, 'build', '--temp'])
let b:Run = function('Make', [0, 'run', '--temp'])
