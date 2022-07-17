" Use sh (usually maps to dash terminal) for better POSIX compliance
"noremap <silent> <leader>2 :call BuildAndRun($TMPDIR . '/preview', 'chmod 755 ' . $TMPDIR . '/preview', $TMPDIR . '/preview')<CR>
"noremap <silent> <leader>3 :call PreviewOpen($TERMINAL . ' -e')<CR>
"noremap <silent> <leader>4 :call PreviewClose()<CR>
"noremap <silent> <leader>l :call PreviewSendLine('shellcheck ' . expand('%:p'))<CR>

"let b:ale_lint_on_text_changed = 'never'
"let b:ale_lint_on_insert_leave = 0
"let b:ale_lint_on_save = 1
"let b:ale_lint_on_enter = 0

let s:run_line = '#run:\(.*\)'

let b:BuildBackground = function('Make', [0, 'build', ''])
let b:Build = function('Make', [1, 'build', ''])
let b:Run = function('CustomisableMake', [s:run_line, 'build', ''])
let b:Lint = function('Make', [1, 'lint', ''])
