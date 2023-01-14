let s:run_line = '//run:\(.*\)'

function! s:Lint() abort
  write
  let l:pos = getcurpos()
  silent! execute("%.!goimports %")
  call setpos('.', l:pos)
endfunction

let b:BuildBackground = function('RunCmdlineOverload', [s:run_line, function('ShellRun', ['go', 'run', expand('%')]),  function('ShellRun')])
" TODO: No way to use taint mode for `b:Build` default with new system
let b:Build = function('Make', [1, 'build', ''])
let b:Run = function('CustomisableMake', [s:run_line, 'run', ''])
let b:Lint = function('<SID>Lint')
