"let s:run_line = '<!--run:\(.*\)-->'
"
"" autocmd FileType markdown noremap <F2> :call PreviewSendLine('pandoc | lynx -stdin')<CR>
"" autocmd FileType markdown noremap <F3> :call PreviewOpenWindow(terminal_execute)<CR>
"" nnoremap <F2> :silent w !pandoc -o /tmp/preview.pdf<CR>
"" nnoremap <F3> :silent! !evince /tmp/preview.pdf &>/dev/null &<CR>:redraw!<CR>
"
""augroup markdown
""  " vim-markdown-toc eats lines if ToC is folded
""  autocmd BufWritePre *.md normal! zR
""augroup END
""
"""nnoremap <C-Space> :call MarkdownFollowLink()<CR>
"""nnoremap <Leader>tc :call MarkdownTableOfContents()<CR>
""nnoremap <silent> <Leader><Space> :call MarkdownFollowLink()<CR>
""
""inoremap <buffer> <LocalLeader>back
""  \ [back to toc](#Table%20of%20Contents)<CR>
""
""inoremap <buffer> <LocalLeader>toc
""  \ # Table of Contents<C-o>:GenTocCommonMark<CR>
""  \<C-o>o
"
"
"" Maintain parity with 'asciidoc.vim' and 'rmd.vim'
"function! s:Run() abort
"  call RunCmdlineOverload(s:run_line,
"    \function('s:RunDefault'),
"    \function('s:RunWithArguments'))
"endfunction
"
"function! s:RunDefault() abort
"  " Probably should use the output of `compile.sh`
"  let l:path = $TMPDIR . "/" . expand('%:t:r') . ".html"
"  if !filereadable(l:path)
"    call s:Build()
"  endif
"  " Do not want necessarily need setsid
"  " `falkon` has live reload
"  call system('falkon --private-browsing --no-extensions --new-window '
"    \ . shellescape(l:path) . ' >/dev/null 2>&1&')
"endfunction
"
"function! s:RunWithArguments(cmdline) abort
"  execute('vertical T ' . a:cmdline)
"endfunction
"
""function! Lint()
""endfunction
"
"let b:BuildBackground = function('Make', [0, 'build', '--temp'])
"let b:Build = function('Make', [1, 'build', '--temp'])
"let b:Run = function('<SID>Run')
