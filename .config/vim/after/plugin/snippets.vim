" ==============================================================================
" Vim Snippets
" ==============================================================================
" Automatically detect from &filetype
inoremap <unique>        <LocalLeader>t     <C-v><Tab>
inoremap <unique>        <LocalLeader><Tab> <C-r>=ChooseSnippet(&filetype)<CR>
inoremap <unique>        <LocalLeader>ss    <C-r>=ChooseSnippet("symbols")<CR>
inoremap <unique> <expr> <LocalLeader>sa    '<C-r>=ChooseSnippet("'
  \ .  input("Choose filetype for snippet.sh: ") . '")<CR>'
inoremap <unique>        <LocalLeader>sl     <C-o>:silent read !snippets.sh -t<CR>


" The dashes
" Move cursor and replace placeholder '<>'
inoremap <unique> <LocalLeader>p <C-o>?<><CR><C-o>d2l
inoremap <unique> <LocalLeader>n <C-o>/<><CR><C-o>d2l
nnoremap <unique> <LocalLeader>p ?<><CR>c2l
nnoremap <unique> <LocalLeader>n /<><CR>c2l

" Populate the popup menu based on the &filetype
function ChooseSnippet(filetype) abort
  let b:complete_start= [line('.'), col('.'), a:filetype]
  let l:blob = system("snippets.sh --list -- " . a:filetype)
  let l:choices = []
  for line in split(l:blob, '\n')
    let l:csv = split(line, ',')
    if len(l:csv) >= 2
      call add(l:choices, {
        \ 'word': l:csv[1],
        \ 'menu': l:csv[2],
      \ })
    endif
  endfor
  call complete(col('.'), l:choices)
  " 'complete()' inserts directly so return '' to not insert a '0'
  return ''
endfunction

" Uses the @" (yank) register to insert
function InsertSnippet() abort
  if exists('b:complete_start')
    if has_key(v:completed_item, 'word')
      let l:selection = v:completed_item['word']
      let l:len =  strlen(l:selection)

      stopinsert
      normal! hv
      call cursor(b:complete_start[0], b:complete_start[1])
      normal! x
      call cursor(b:complete_start[0], b:complete_start[1])
      let @" = system("snippets.sh " . b:complete_start[2] . " " . l:selection
        \ . " 2>/dev/null")
      setlocal paste
      execute("normal! i\<C-r>\"")
      setlocal nopaste
    endif

    unlet b:complete_start
  endif
endfunction

augroup Snippets
  autocmd!
  autocmd CompleteDone * call InsertSnippet()
augroup END


