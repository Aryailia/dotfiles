let s:run_line = '//run:\(.*\)'
set suffixesadd=.java

let b:BuildBackground = function('Make', [0, 'build', ''])
let b:Build =  function('CustomisableMake', [s:run_line, 'build', ''])
let b:Run = function('CustomisableMake', [s:run_line, 'run', ''])
