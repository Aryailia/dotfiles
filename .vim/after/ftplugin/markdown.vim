" autocmd FileType markdown noremap <F2> :call PreviewSendLine('pandoc | lynx -stdin')<CR>
" autocmd FileType markdown noremap <F3> :call PreviewOpenWindow(terminal_execute)<CR>
" nnoremap <F2> :silent w !pandoc -o /tmp/preview.pdf<CR>
" nnoremap <F3> :silent! !evince /tmp/preview.pdf &>/dev/null &<CR>:redraw!<CR>

augroup markdown
  " vim-markdown-toc eats lines if ToC is folded
  autocmd BufWritePre *.md normal! zR
augroup END

"nnoremap <C-Space> :call MarkdownFollowLink()<CR>
"nnoremap <Leader>tc :call MarkdownTableOfContents()<CR>
nnoremap <silent> <Leader><Space> :call MarkdownFollowLink()<CR>

inoremap <buffer> <LocalLeader>back
  \ [back to toc](#Table%20of%20Contents)<CR>

inoremap <buffer> <LocalLeader>toc
  \ # Table of Contents<C-o>:GenTocCommonMark<CR>
  \<C-o>o
