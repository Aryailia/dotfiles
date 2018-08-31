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



" =====================
" Pane version
function! s:CheckHaveTmux()
  call system('command -v tmux')
  if v:shell_error != 0
    echoerr 'Tmux is not installed'
  endif
  return !v:shell_error
endfunction

function! s:CreateUUID()
  return substitute(expand('%:t'), '\.', '-', 'g') . localtime()
endfunction

function! s:SetPaneID()
  " tmux checks will occur in global commands

  if !exists('b:PreviewUUID') || b:PreviewUUID == ''
    " TMUX_PANE is set by tmux so if not in a tmux session
    " if $TMUX_PANE == ''
      " -dont focus current, -Print, -Format print
      let l:cmd = 'tmux new-session -d -PF "#{pane_id}" '
      let l:id = system(l:cmd . '-s "' . s:CreateUUID() . '"')
      let b:PreviewUUID = substitute(l:id, '[\s\n]', '', 'g')
    " else
      " -horizontal (right), -dont focus new pane, -Print, -Format print
      " let b:PreviewUUID = system('tmux split-window -hdPF "#{pane_id}"')
    " endif
  endif
  return b:PreviewUUID
endfunction

function! s:PreviewClearPaneID()
  let b:PreviewUUID = ""
endfunction

function! PreviewOpen(emulatorRun)
  if ! s:CheckHaveTmux() | return | endif

  let l:emulator = substitute(a:emulatorRun, '^\([^ ]\+\).*', '\1', '')
  let l:testX = 'command -v xset >/dev/null 2>&1 && echo 1'
  let l:testCmd = l:emulator == ''
    \ ? ''
    \ : 'command -v ' . l:emulator .  ' >/dev/null 2>&1 && echo 1'

  " If in a tmux session, tmux pane should be set
  if $TMUX_PANE != ''
    call s:PreviewClearPaneID()
    let l:paneID = s:SetPaneID()
    " -horizontal (right), -dont focus new pane, -source pane
    call system('tmux join-pane -hds ' . l:paneID)

  " If X running, X is installed, and the a:emulatorRun exists
  elseif $DISPLAY != '' && system(l:testX) == '1' && system(l:testCmd) == '1'
    let l:paneID = s:SetPaneID()
    let l:spawnSession = ' tmux new-session -A -s ' . s:CreateUUID() . ' &'
    call system(a:emulatorRun . l:spawnSession)

  " Forgot to run tmux and cannot launch preview (cause no X), just 
  else
    let l:paneID = s:SetPaneID()
  endif

  echom 'Created a tmux preview window'
  " emacs free ctrl command (also check insert mode for vim)
  " emacs insert mode for vim?
  " Find out how to go to tmp
endfunction

function! PreviewSendKeys2(cmd)
  if !s:CheckHaveTmux() | return | endif
  call system('tmux send-keys -t ' . s:SetPaneID() . ' ' . a:cmd)
endfunction

function! PreviewSendLine2(text)
  call PreviewSendKeys2('"' . escape(a:text, '\"$`') . '" Enter')
endfunction

