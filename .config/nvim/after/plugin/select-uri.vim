"if exists(s:thenameofthispluginloaded)
"  finish
"endif

noremap <Plug>SelectNextURI :call <SID>SelectNextURI()<CR>

function! s:SelectNextURI()
  let l:search = execute("w !uriscan.sh -r " . line('.') . " -c " . (col('.') + 1))
  let l:match = matchlist(l:search, '\v(\d+) (\d+)\|(\d+) (\d+)\|')
  echo system("notify.sh '" . l:search . "'")
  if (len(l:match) >= 5)
    execute("normal! " . l:match[1] . "G" . l:match[2] . "|")
    normal! v
    if col('.') != l:match[2]
      normal! lol
    endif
    execute("normal! " . l:match[3] . "G" . l:match[4] . "|")
  else
    echo "No links or paths found from cursor to end of file"
  endif
endfunction
