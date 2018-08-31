" For Reference
" Tmux -t: <session>:<window>.<pane>
" Eg.: preview-sh-12345:<window_name>.<pane_name>

" Enforce tmux dependency
function! s:HasTmux()
  " Command defined in POSIX, checks if installed
  call system('command -v tmux >/dev/null 2>&1')
  if v:shell_error != 0
    echoerr '`tmux` not found in $PATH'
  endif
  return !v:shell_error
endfunction

" Create/attach to the pseudo-unique session in
" Filename + timestamp should be unique enough
function! s:UUID()
  return substitute(expand('%:t'), '\.', '-', 'g') . localtime()
endfunction

" Send-keys of nothing to the pane and see if it errors
function! s:IsPaneActive()
  " Guard against b:PreviewUUID not existing
  return exists('b:PreviewUUID')
    \ && b:PreviewUUID != ''
    \ && system('tmux send-keys -t "' . b:PreviewUUID . '" "" >/dev/null 2>&1'
    \ . ' && printf "1"') == '1'

endfunction

" Return the pane, if not set create a new session for it
function! s:GetSetPaneID()
  " tmux checks will occur in global commands
  " reset ID if pane was closed
  if !s:IsPaneActive() 
    let b:PreviewUUID = ''
  endif

  if !exists('b:PreviewUUID') || b:PreviewUUID == ''
    " -dont focus current, -Print, -Format print
    let l:cmd = 'tmux new-session -d -PF "#{pane_id}" '
    let l:id = system(l:cmd . '-s "' . s:UUID() . '"')
    let b:PreviewUUID = substitute(l:id, '[\s\n]', '', 'g')
  endif
  return b:PreviewUUID
endfunction

" eg: :call PreviewOpenWindow("bash -e")
function! PreviewOpen(emulatorRun)
  " Depends on tmux
  if ! s:HasTmux()
    return
  endif

  let l:paneID = s:GetSetPaneID()

  let l:emulator = substitute(a:emulatorRun, '^\([^ ]\+\).*', '\1', '')
  let l:testX = 'command -v xset >/dev/null 2>&1 && printf 1'
  let l:testCmd = l:emulator == ''
    \ ? ''
    \ : 'command -v ' . l:emulator .  ' >/dev/null 2>&1 && printf 1'
  
  " If in a tmux session, tmux pane should be set
  if $TMUX_PANE != ''
    " -horizontal (right), -dont focus new pane, -source pane
    call system('tmux join-pane -hds ' . l:paneID)

  " If X running, X is installed, and the a:emulatorRun exists
  elseif $DISPLAY != '' && system(l:testX) == '1' && system(l:testCmd) == '1'
    let l:spawnSession = ' tmux new-session -dA -s ' . s:UUID()
    call system('setsid ' a:emulatorRun . l:spawnSession . ' >/dev/null 2>&1')

  " Not running in tmux and cannot launch preview (cause no X)
  else
    " Just do the echom
  endif

  echo 'Created a tmux preview window'
  " emacs free ctrl command (also check insert mode for vim)
  " emacs insert mode for vim?
  " Find out how to go to tmp
endfunction

function! PreviewSendKeys(keys)
  if !s:HasTmux()
    return
  endif
  call system('tmux send-keys -t ' . s:GetSetPaneID() . ' ' . a:keys)
endfunction

function! PreviewSendLine(text)
  call PreviewSendKeys('"' . escape(a:text, '\"$`') . '" Enter')
endfunction

function! PreviewClose()
  if s:IsPaneActive()
    call system('tmux kill-pane -t "' . b:PreviewUUID . '"')
    let b:PrevieUUID = ''
  endif
endfunction
