" Finds any line with #:vim and returns it
" For use when wanting to add arguments to any run command
function! GetVimLine()
  let l:currentbuffer = join(getline(1, '$'), "\n")
  " only use the first, also easier to test for no matches with simplier logic
  let l:vimline = matchlist(l:currentbuffer, '!:console \(.\{-}\)\n')
  if len(l:vimline) > 0
    return l:vimline[1]
  else
    return ""
  endif
endfunction

" Should also work for languages without a compile step
" a:tempfile is the full path, typically resides in the temp directory
" a:compile usually will reference the same string as a:tempfile
" a:default is the default run script
" Printf-esque style %compiledfile and %self in a:compile and a:default
" If it is a custom script, you also get %self
function! BuildAndRun(tempfile, compile, default)
  " Full path without file extension
  let l:bin = expand('%:p:r')
  silent execute 'write!' a:tempfile
  silent call PreviewSendLine(s:ApplyFilename(a:compile, l:bin))
  let l:vimline = GetVimLine()

  " If special console line exists, then use that instead of a:default
  if l:vimline == ""
    silent call PreviewSendLine(s:ApplyFilename(s:ApplySelf(a:default), l:bin))
  else
    " Allows you to do `run %self` or `run %self -o %compiledfile`
    silent call PreviewSendLine(s:ApplyFilename(s:ApplySelf(l:vimline), l:bin))
  endif
endfunction 

function! s:ApplyFilename(format, filename)
  return substitute(a:format, '%compiledfile', a:filename, 'g')
endfunction

function! s:ApplySelf(format)
  return substitute(a:format, '%self', expand('%:p'), 'g')
endfunction
