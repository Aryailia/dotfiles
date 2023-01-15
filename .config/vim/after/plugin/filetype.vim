" This is to facilitate all the programming languages FileType customisations

noremap <unique> <silent> <Leader>1 :call b:BuildBackground()<CR>
noremap <unique> <silent> <Leader>2 :call b:Build()<CR>
noremap <unique> <silent> <Leader>3 :call b:Run()<CR>
noremap <unique> <silent> <Leader>4 <C-w><C-w>G<C-w><C-w>
noremap <unique> <silent> <Leader>5 :vertical Tclose!<CR>
noremap <unique> <silent> <Leader>l :call b:Lint()<CR>

vnoremap <unique> <silent> <Leader>ot y:call system(
  \"$TERMINAL -e handle.sh terminal --file " . @")<CR>
nnoremap <unique> <silent> <Leader>ot :call system(
  \"$TERMINAL -e handle.sh terminal --file " . ExpandCFileWithSuffix())<CR>
vnoremap <unique> <silent> <Leader>og
  \ y:call system("handle.sh gui --file " . @")<CR>
nnoremap <unique> <silent> <Leader>og
  \ :call system("handle.sh gui --file " . ExpandCFileWithSuffix())<CR>
nnoremap <unique> <Leader>;l :call ListUrls()<CR>

" Visual-mode select the next URI if valid URL or if path to existing file
nmap <unique> <C-l>     <Plug>SelectNextURI
imap <unique> <C-l>     <C-o><Plug>SelectNextURI
vmap <unique> <C-l>     <Esc><Plug>SelectNextURI



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
" b:Build(), b:Run(), b:Lint() are defined in filetype for customisation
" These functions are used in the ftplugin .vim files

" Detects the line specified by {s:regexp}, and
" runs the command the follows (allows regexp capture groups)
"
" Replaces '%' with the path to file
" Use '%%' to get literal '%'
function! RunCmdlineOverload(regexp, notfound, found) abort
  let l:overload = searchpos(a:regexp, 'nw')
  if l:overload[0] == 0
    call a:notfound()
  else
    " the '@' substitutions are just to map '%' and '%%' properly
    let l:path = substitute(expand('%'), '\m%', '@B', '')
    " By convention, all these custom runners will be only on one line
    let l:cmd = matchlist(getline(l:overload[0]), a:regexp)[1]
    let l:cmd = substitute(l:cmd, '\m@', '@A', 'g')
    let l:cmd = substitute(l:cmd, '\m%%', '@B', 'g')
    let l:cmd = substitute(l:cmd, '\m%', l:path, 'g')
    let l:cmd = substitute(l:cmd, '\m@B', '%', 'g')
    let l:cmd = substitute(l:cmd, '\m@A', '@', 'g')
    call a:found(l:cmd)
  endif
endfunction

" Probably to what you want to set b:BuildBackground() and b:Build()
function! Make(is_run_in_split, build_type, temp) abort
  write
  let l:path = ' ' . shellescape(expand('%'))
  if a:is_run_in_split
    execute('vertical T build.sh ' . a:build_type . ' ' . a:temp . l:path)
  else
    " NOTE: .tex files need this to not be `AsyncRun setsid build.sh`
    execute('AsyncRun build.sh  ' . a:build_type . ' ' . a:temp . l:path)
  endif
endfunction

function! ShellRun(cmdline) abort
  execute('AsyncRun ' . a:cmdline)
endfunction

" For calling when there are arguments by CustomisableMake()
function! SplitRunShell(cmdline) abort
  write
  execute('vertical T ' . a:cmdline)
endfunction


" Run the comment as a shell command
function! ShellMake(regexp) abort
  " 'getpid' is just a no-op
  call RunCmdlineOverload(a:regexp
  \, function('getpid')
  \, function('SplitRunShell')
  \)
endfunction

" Probably to what you want to set b:Run()
function! CustomisableMake(regexp, build_type, temp) abort
  call RunCmdlineOverload(a:regexp
  \, function('Make', [1, a:build_type, a:temp])
  \, function('SplitRunShell')
  \)
endfunction

" Probably to what you want to set b:Lint()
function! Lint() abort
  vertical T build.sh lint %
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

