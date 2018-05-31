" Tmux dependency

" Get the session name for the tmux preview instance unique to current buffer
" Tmux is: session > window > pane
" Filename + timestamp should be unique enough
function! s:UUID()
  let b:PreviewUUID = exists('b:PreviewUUID') ? b:PreviewUUID :
    \ substitute(expand('%:t'), '\.', '-', 'g') . localtime() 
  return b:PreviewUUID
endfunction

" Create/attach to the pseudo-unique session in
" a:emulatorExecute should spawn a window (think emulator not shell)
" eg: :call PreviewOpenWindow("bash -e")
function! PreviewOpenWindow(emulatorExecute)
  let l:spawnSession = ' tmux new-session -A -s ' . s:UUID() . ' &'
  call system(a:emulatorExecute . l:spawnSession)
endfunction

function! PreviewSendKeys(cmd)
  let l:pane = s:UUID() . ':0.0'
  " Spawn not duplicate a detached (no context switch) tmux session
  call system('tmux new-session -d -s ' . s:UUID()) 
  call system('tmux send-keys -t ' . l:pane . ' ' . a:cmd)
endfunction

" Sends Text and an Enter
function! PreviewSendLine(text)
  call PreviewSendKeys('"' . escape(a:text, '\"$`') . '" Enter')
endfunction

