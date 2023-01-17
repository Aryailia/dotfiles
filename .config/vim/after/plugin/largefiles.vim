" Make reading large files faster, and probably do not want to edit

" https://vim.fandom.com/wiki/VimTip343 "Faster loading of large files"

augroup LargeFiles
  autocmd!
  autocmd BufReadPre  *        call <SID>LargeFile(1, expand('<afile>'))
  autocmd BufLeave    <buffer> call <SID>LargeFile(0, expand('<afile>'))
augroup END


function! s:LargeFile(is_enter, path) abort
  let l:size = getfsize(a:path)
  if l:size >= 100 * 1024 * 1024 " files >= 100 MB
    if a:is_enter
      syntax clear
      setlocal binary   bufhidden=unload nofoldenable eventignore+=FileType
      setlocal readonly nomodifiable
      if v:version > 704
        setlocal undolevels=-1
      endif
    else
      setlocal nobinary bufhidden=       foldenable   eventignore-=FileType
      if v:version > 704
        setlocal undolevels=1000
      endif
    endif
  endif
endfunction
