let s:run_line = '//run:\(.*\)'

"function! s:Lint()
"endfunction

let b:BuildBackground = function('Make', [0, 'build', '--temp'])
let b:Build = function('CustomisableMake', [s:run_line, 'build', '--temp'])
