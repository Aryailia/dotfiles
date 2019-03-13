function! s:Runner()
  echo 'yo'
endfunction

function! Runner()
  call s:SpawnSplit()
  "term_sendkeys('', "echo asdf\<CR>")
endfunction

function! s:SpawnSplit()
  if !exists('b:SplitTR_terminal_id') || win_id2win(b:SplitTR_terminal_id) == 0
    vertical terminal
    let b:SplitTR_terminal_id = win_getid()
    let g:last_terminal_job_id = b:terminal_job_id
    wincmd p
    echo b:terminal_job_id
  endif
endfunction

nnoremap <silent> <Plug>Runner :call <SID>Runner<CR>
nnoremap <Leader>zv <Plug>(Runner)
nnoremap <Leader>zc :call Runner()<CR>
