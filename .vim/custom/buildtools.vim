" Finds any line with #:vim and returns it
" For use when wanting to add arguments to any run command
function! GetVimLine()
  let l:currentbuffer = join(getline(1, '$'), "\n")
  let l:command = matchlist(l:currentbuffer, '#:vim \(.\{-}\)\n')
  if len(l:command) > 0
    return l:command[1]
  else
    return ""
  endif
endfunction

function! BuildAndRun(compiler)
  let l:temp = '/tmp/precompile.txt'
  " Strip out path and extension; left with just file title
  let l:bin = expand('%:t:r')
  execute 'write!' l:temp
  call PreviewSendLine(a:compiler . ' ' . l:temp . ' -o ' . l:bin)
  let l:args = GetVimLine()
  if l:args == ""
    call PreviewSendLine('./' . l:bin)
  else
    call PreviewSendLine('./' . l:bin . ' ' . l:args)
  endif
endfunction 
