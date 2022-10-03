let s:run_line = '<!--run:\(.*\)-->'

function s:Run() abort
  silent !falkon --private-browsing --no-extensions --new-window
    \ "%" >/dev/null 2>&1&
endfunction

let b:Build = function('<SID>Run')
let b:Run = function('<SID>Run')


"let b:BuildBackground = function('Make', [0, 'build', '--temp'])
" use tetra-cli?
let b:BuildBackground = function('RunCmdlineOverload', [s:run_line, function('getpid'), function('ShellRun')])
let b:Build = function('CustomisableMake', [s:run_line, 'build', '--temp'])
let b:Run = function('<SID>Run')


"function! Lint()
"endfunction

