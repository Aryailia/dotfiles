" This is to facilitate all the programming languages FileType customisations

" Integrate 'build.sh' and 'kassio/neoterm' into workflow

noremap <unique> <silent> <Leader>q :execute('silent ![ -n "${TMUX}" ] && tmux new-window -d build.sh background --temp ' . shellescape(expand('%')))<CR>
noremap <unique> <silent> <Leader>w :execute('silent !tmux-alt-pane.sh send-keys "build.sh build --temp "' . shellescape(expand('%')) . " Enter")<CR>
noremap <unique> <silent> <Leader>e :execute('silent !tmux-editor-run.sh ' . &filetype . ' ' . shellescape(expand('%')) )<CR>
noremap <unique> <silent> <Leader>r :execute('silent !tmux-alt-pane.sh send-keys "build.sh run --temp "' . shellescape(expand('%')) . " Enter")<CR>
noremap <unique> <silent> <Leader>t :execute("silent !tmux-alt-pane.sh kill-pane")<CR>
noremap <unique> <silent> <Leader>l :execute('silent !tmux-alt-pane.sh send-keys "build.sh lint "' . shellescape(expand('%')) . " Enter")<CR>

vnoremap <unique> <silent> <Leader>ot y:call system(
  \"$TERMINAL -e handle.sh terminal --file " . @")<CR>
nnoremap <unique> <silent> <Leader>ot :call system(
  \"$TERMINAL -e handle.sh terminal --file " . ExpandCFileWithSuffix())<CR>
vnoremap <unique> <silent> <Leader>og
  \ y:call system("handle.sh gui --file " . @")<CR>
nnoremap <unique> <silent> <Leader>og
  \ :call system("handle.sh gui --file " . ExpandCFileWithSuffix())<CR>
nnoremap <unique> gl :call ListUrls()<CR>


" Blank *.tex files default to 'plain' (affects which ftplugin gets used)
let g:tex_flavor = 'latex'  " See :h filetype-overrule

"" Help FileType (ftplugin) with identification
"augroup FileTypeHelpers
"  autocmd!
"  "autocmd BufNewFile,BufRead *.md   set filetype=markdown
"  "autocmd bufNewFile,BufRead *.plot set filetype=gnuplot
"  "autocmd bufNewFile,BufRead *.tex  set filetype=tex
"augroup END



" ==============================================================================
" Compilation
" ==============================================================================
function CustomisableMake() abort
endfunction

" Use the LocationList to display
" Not sure how I want to approach highlighting
" TODO: uriscan.sh on 'coolstuff.md' has some problems
" TODO: convert this to :lgrep // %
function ListUrls() abort
  let l:current_window_id = winnr()
  let l:cursor_x = line('.')
  let l:cursor_y = col('.')
  " just a big number
  let [l:dx, l:dy] = [0, 0]
  let l:target = 0

  let l:uri_scan = execute("write !uriscan.sh -f")
  let l:list = []
  let l:current_buffer_id = bufnr()
  let l:index = 1
  for line in split(l:uri_scan, '\n')
    let l:entry = split(line, '|')
    if len(l:entry) == 3
      let [l:x, l:y] = split(l:entry[0], ' ')

      if l:target <= 0 || abs(l:x - l:cursor_x) < l:dx
        \ || (abs(l:x - l:cursor_x) == l:dx && abs(l:y - l:cursor_y) <= l:dy)
        let l:dx = abs(l:x - l:cursor_x)
        let l:dy = abs(l:y - l:cursor_y)
        let l:target = l:index
      endif
      call add(l:list, {
        \ 'bufnr': bufnr(),
        \ 'lnum': l:x,
        \ 'col':  l:y,
        \ 'text': l:entry[2],
      \ })
      let l:index += 1
    endif
  endfor

  call setloclist(0, list)
  if l:target >= 1 | execute 'lfirst ' . l:target | endif
  lopen
  " 'lopen' moves to location list, return to the main window
  execute l:current_window_id . 'wincmd w'
endfunction

function ExpandCFileWithSuffix() abort
  let l:path = expand('<cfile>:p')
  let l:path = substitute(l:path, '\\', '\\\\', 'g')
  let l:path = substitute(l:path, '"', '\\"', 'g')
  "echo "sh -c 'printf %s \"" . l:path . "\"'"
  let l:path = system("sh -c 'printf %s \"" . l:path . "\"'")
  for l:ext in split(&suffixesadd, ",")
    let l:path_with_ext = l:path . l:ext
    if filereadable(l:path_with_ext)
      return l:path_with_ext
    endif
  endfor
  return l:path
endfunction

