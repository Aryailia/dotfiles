set nocompatible

" ==============================================================================
" Vi Compatible
" ==============================================================================

set autoindent     " Use indent of previous line on new lines
set number         " Display row number
set ruler          " Display row and column number as a status bar
set showmode       " Display insert/command/normal mode as a status bar

" ==============================================================================
" General Editor Behaviour Settings
" ==============================================================================

" Respect XDG Base Directory Specification, https://tlvince.com/vim-respect-xdg
set directory  =$XDG_CACHE_HOME/vim/swap,/tmp
set backupdir  =$XDG_CACHE_HOME/vim/backup,/tmp
set viminfofile=$XDG_CACHE_HOME/vim/viminfo
set runtimepath=$XDG_CONFIG_HOME/vim,$XDG_CONFIG_HOME/vim/after,$VIM,$VIMRUNTIME
let g:vimdotdir=$XDG_CONFIG_HOME . "/vim"
"" Let '$VIMINIT' handle this
"let $MYVIMRC="$XDG_CONFIG_HOME/vim/init.vim"
"" 'runtimepath' sets this
"let g:netrw_home=/dev/null

set laststatus=2            " Always on
set statusline=[%n]\ %<%f%m " buffer (%n) truncate (%<) path (%f) modified (%m)

if has("syntax") | syntax enable | endif
filetype plugin indent on

set nobackup
set noswapfile
set nowritebackup
set splitbelow     " New horizontal window splits open below
set splitright     " New vertical window splits open to the right

set t_vb=  " Disable visual bell
"set ttyfast
"set showcmd

set norelativenumber      " this kills performance
syntax sync minlines=256  " improve syntax performance
set nocursorcolumn        " is default off, but better performance
set nocursorline          " is default off, but better performance


set ignorecase
set incsearch   " Search highlights only next result as you type

" The all-important default indent settings; filetypes to tweak
set expandtab      " Use spaces instead of tabs, use C-v to enter tabs
set shiftwidth=2   " Indent with two spaces


if v:version >= 800
  set nofixendofline      " Do not auto-change the last character in a file
  set foldmethod=indent   " I dislike automatic collapsing
  "set nofoldenable        " Expand all collapsed sections
endif
set bg=light          " Readable on light background

" Linting stuff
set colorcolumn=81  " Archaic 80-character width, keep to before the line
highlight ColorColumn ctermfg=red ctermbg=yellow guibg=cyan
highlight HighlightedWhitespace ctermbg=Grey guibg=Grey
call matchadd('HighlightedWhitespace', '\t')
call matchadd('HighlightedWhitespace', '\s\+$')
call matchadd('HighlightedWhitespace', '　\+$')
highlight Visual cterm=NONE ctermbg=LightYellow ctermfg=NONE

" Wildmenu settings; see also plugin/wildignore.vim
set wildmenu                " Use wildmenu
set wildmode=list:longest   " Tab press completes and lists
silent! set wildignorecase  " Case insensitive, if supported

let mapleader = '\'
let maplocalleader = '	'

" the `autocmd!` deletes previous bindings if sourced again
" Not sure if this even helps but to help when sourcing for editing
mapclear | mapclear! | mapclear <buffer> | mapclear! <buffer>

" Automatically executes `filetype plugin indent on` and `syntax enable`
" :PlugInstall to install
if filereadable(g:vimdotdir . '/autoload/plug.vim')
  call plug#begin(g:vimdotdir . '/package')
    Plug 'tpope/vim-surround'         " Adding quotes
    Plug 'kassio/neoterm'             " Terminal for vim and neovim
    Plug 'skywind3000/asyncrun.vim'   " Run scripts in the background async

    Plug 'ap/vim-css-color', { 'commit': 'bb34fb4'} " Color hex colour values
    Plug 'rust-lang/rust.vim'         " Rust syntax highlighting
    Plug 'habamax/vim-asciidoctor'    " Stock adoc syntax highlighting is slow
    Plug 'hashivim/vim-terraform'     " Syntax highlighting for terraform

    "Plug 'prabirshrestha/vim-lsp'     " Language-Server Protocol client
    "Plug 'prabirshrestha/asyncomplete.vim'     " Show omni menu while typing
    "Plug 'prabirshrestha/asyncomplete-lsp.vim' " Source from vim-lsp
  call plug#end()
endif

" This should be set after `filetype plugins ident on`.
augroup GeneralCustom
  autocmd!
  autocmd FileType * set formatoptions-=c formatoptions-=r formatoptions-=o formatoptions+=j
  autocmd FileType * normal zR
augroup END

set nrformats-=octal  " Leading 0s are not recognised as octals
"set formatoptions+=j  " Delete comment leaders when joining lines
"set formatoptions-=c  " Do not auto-wrap comments when exceeding textwidth
"set formatoptions-=o  " Do not auto add comments on normal 'o' or 'O'
"set formatoptions-=r  " Do not auto add comments on <Enter>
set listchars=nbsp:¬,extends:»,precedes:«,trail:• " Visually show these hidden chars

" ==============================================================================
" General Bindings
" ==============================================================================
"noremap           <F1> <Esc>
" Use unique everywhere so it yells at me if I duplicate a keybind
" Disable Ex mode (can still use gQ)
nnoremap <unique> Q <Nul>

" Inspired by 'tpope/vim-unimpaired'
nnoremap <unique> yor :setlocal <C-r>=&rnu      ? "no":""<CR>rnu<bar>setlocal rnu?<CR>
nnoremap <unique> yop :setlocal <C-r>=&paste    ? "no":""<CR>paste<bar>setlocal paste?<CR>
nnoremap <silent> <expr> <unique> yos &spell
  \? ':setlocal nospell<Bar>setlocal spell?<CR>'
  \: ':setlocal spell spelllang=' . input('spelllang=', 'en_gb') . '<Bar>setlocal spelllang?<CR>'
nnoremap <unique> yoh :setlocal <C-r>=&hlsearch ? "no":""<CR>hlsearch<bar>setlocal hlsearch?<CR>
nnoremap <unique> yon :setlocal <C-r>=&number   ? "no":""<CR>number<bar>setlocal number?<CR>
nnoremap <unique> [q  :colder
nnoremap <unique> ]q  :cnewer
nnoremap <unique> [l  :lolder
nnoremap <unique> ]l  :lnewer

" Spelling
nnoremap <unique> <Leader>sus :set spelllang=en_US,cjk<CR>
nnoremap <unique> <Leader>sgb :set spelllang=en_GB,cjk<CR>

" 'j' and 'k' move visual lines, Ctrl versions to move the original real lines
nnoremap <unique> j     gj
vnoremap <unique> j     gj
nnoremap <unique> k     gk
vnoremap <unique> k     gk
nnoremap <unique> <C-j> j
vnoremap <unique> <C-j> j
nnoremap <unique> <C-k> k
vnoremap <unique> <C-k> k

" Select the same selection again after doing an indent
vnoremap <unique> > >gv
vnoremap <unique> < <gv

" Saving
nnoremap <unique> <leader>s :write<CR>
nnoremap <unique> <C-s>     :write<CR>
inoremap <unique> <C-s>     <C-o>:write<CR>

" Set IME to the decativated version (i.e. english keyboard) for normal mode
" IMEs by convention have two states: active and deactivated.
" Extraction of 'rlue/vim-barbaric', this has more elaborate logic that is
" will not always activate your IME if you deactivated it.
"
" But if you do want to always activate it (always proc e.g. Japanese on insert
" mode) as we do here, a good idea is to have two english keyboards, one for
" the deactivated version and one for the active. That way you can, outside of
" vim, activate an English keyboard to stay in English on insert mode.
"
" I choose this over 'rlue/vim-barbaric' because 1) less plugins and 2) I always
" want to be in English for normal mode. 'rlue/vim-barbaric' maintains whatever
" mode you started with on entering vim
set timeoutlen  =1000 " https://github.com/rlue/vim-barbaric/issues/15
set ttimeoutlen =0    " Immediately run fcitx-remote after entering/leaving
augroup CustomBarbaric
  autocmd!
  autocmd InsertEnter * if executable('fcitx-remote') | call system('fcitx-remote -o') | endif
  autocmd InsertLeave * if executable('fcitx-remote') | call system('fcitx-remote -c') | endif
  " This always prints some ANSI escape codes, not sure how to fix it
  " Deactivate on VimEnter
  "autocmd VimEnter    * if executable('fcitx-remote') | call system('fcitx-remote -c') | endif
augroup END


" ==============================================================================
" Clipboard
" ==============================================================================
" Consider trick of `if has("clipboard") @+ = @* = @"` ?
nnoremap <unique> <Leader>c :silent call system("clipboard.sh --write", @")<CR>
vnoremap <unique> <Leader>c y:call system('clipboard.sh --write', @")<CR>gv
inoremap <unique> <LocalLeader>v
  \ <C-o>:setlocal paste<Bar>
  \let @" = system('clipboard.sh --read')<CR><C-r>"
  \<C-o>:setlocal nopaste<CR>

nmap <unique> <Leader>p a<LocalLeader>v<Esc>
nmap <unique> <Leader>P i<C-v><Esc>
nmap <unique> <Leader>v a<C-p><Esc>
nmap <unique> <Leader>V i<C-p><Esc>

" Visual-mode select the next URI if valid URL or if path to existing file
nmap <unique> <C-l>     <Plug>SelectNextURI
imap <unique> <C-l>     <C-o><Plug>SelectNextURI
vmap <unique> <C-l>     <Esc><Plug>SelectNextURI

augroup CleanupNoPaste
  autocmd!
  autocmd InsertLeave * set nopaste
augroup END

" ==============================================================================
" Compilation
" ==============================================================================
" b:Build(), b:Run(), b:Lint() are defined in filetype for customisation
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

" For calling when there are arguments by CustomisableMake()
function! MakeWithArguments(cmdline) abort
  write
  execute('vertical T ' . a:cmdline)
endfunction

" Run the comment as a shell command
function! ShellMake(regexp) abort
  " 'getpid' is just a no-op
  call RunCmdlineOverload(a:regexp
  \, function('getpid')
  \, function('MakeWithArguments')
  \)
endfunction

" Probably to what you want to set b:Run()
function! CustomisableMake(regexp, build_type, temp) abort
  call RunCmdlineOverload(a:regexp
  \, function('Make', [1, a:build_type, a:temp])
  \, function('MakeWithArguments')
  \)
endfunction

" Probably to what you want to set b:Lint()
function! Lint() abort
  vertical T build.sh lint %
endfunction

noremap <unique> <silent> <Leader>1 :call b:BuildBackground()<CR>
noremap <unique> <silent> <Leader>2 :call b:Build()<CR>
noremap <unique> <silent> <Leader>3 :call b:Run()<CR>
noremap <unique> <silent> <Leader>4 <C-w><C-w>G<C-w><C-w>
noremap <unique> <silent> <Leader>5 :vertical Tclose!<CR>
noremap <unique> <silent> <Leader>l :call b:Lint()<CR>
imap <unique> <silent> <F1> <C-o><Leader>1
imap <unique> <silent> <F2> <C-o><Leader>2
imap <unique> <silent> <F3> <C-o><Leader>3
imap <unique> <silent> <F4> <C-o><Leader>4
imap <unique> <silent> <F5> <C-o><Leader>5

" Use the LocationList to display
" Not sure how I want to approach highlighting
" TODO: uriscan.sh on 'coolstuff.md' has some problems
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

vnoremap <unique> <silent> <Leader>ot y:call system(
  \"$TERMINAL -e handle.sh terminal --file " . @")<CR>
nnoremap <unique> <silent> <Leader>ot :call system(
  \"$TERMINAL -e handle.sh terminal --file " . ExpandCFileWithSuffix())<CR>
vnoremap <unique> <silent> <Leader>og
  \ y:call system("handle.sh gui --file " . @")<CR>
nnoremap <unique> <silent> <Leader>og
  \ :call system("handle.sh gui --file " . ExpandCFileWithSuffix())<CR>
nnoremap <unique> <Leader>;l :call ListUrls()<CR>

" ==============================================================================
" Language Server Protocol (LSP) and autocompletion
" ==============================================================================

"" Auto complete
"inoremap <expr> <Esc> pumvisible() ? "\<C-e>" : "\<Esc>"
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"
"inoremap <expr> <TAB> pumvisible() ? "\<C-y>" : "\<TAB>"
" Avoid completing with only one item. Causes problems when deleting
set completeopt=menu,menuone,preview,noinsert,noselect
nnoremap <unique> <Leader>rn :LspRename<CR>
" e for error
nnoremap <unique> yoe :call ToggleVimLsp()<CR>

nnoremap <unique> gr :LspReferences<CR>
nnoremap <unique> gt :LspTypeDefinition<CR>
nnoremap <unique> gi :LspImplementation<CR>
nnoremap <unique> gd :LspDefinition<CR>
nnoremap <unique> [g :LspPreviousDiagnostic<CR>
nnoremap <unique> ]g :LspNextDiagnostic<CR>
nnoremap <unique> K  :LspHover<CR>


" ==============================================================================
"" Register the LSP servers
"if executable('rls')
"  " Have to repeat install for different streams (stable, nightly, etc.)
"  " rustup add component rls
"  au User lsp_setup call lsp#register_server({
"    \ 'name': 'rls',
"    \ 'cmd': { server_info->['rls'] },
"    \ 'workspace_config': {'rust': {'clippy_preference': 'on' }},
"    \ 'whitelist': ['rust'],
"  \ })
"
"  "au User lsp_setup call lsp#register_server({
"  "  \ 'name': 'rust-analyzer',
"  "  \ 'cmd': { server_info->['rust-analyzer'] },
"  "  \ 'whitelist': ['rust'],
"  "\ })
"endif
"
"if executable('vim-language-server')
"endif
"if executable('javascript-typescript-stdio')
"endif
"if executable('css-languageserver')
"  " sudo npm install --global vscode-css-languageserver-bin
"endif

" ==============================================================================
" Vim Snippets
" ==============================================================================
" Automatically detect from &filetype
inoremap <unique>        <LocalLeader>t     <C-v><Tab>
inoremap <unique>        <LocalLeader><Tab> <C-r>=ChooseSnippet(&filetype)<CR>
inoremap <unique>        <LocalLeader>s     <C-r>=ChooseSnippet("symbols")<CR>
inoremap <unique> <expr> <LocalLeader>i     '<C-r>=ChooseSnippet("'
  \ .  input("Choose filetype for snippet.sh: ") . '")<CR>'
" Backup pop-up list (needs tmux)
inoremap <unique> <LocalLeader>u <C-o>:silent read !snippets.sh -t<CR>


" The dashes
" Move cursor and replace placeholder '<>'
inoremap <unique> <LocalLeader>p <C-o>?<><CR><C-o>d2l
inoremap <unique> <LocalLeader>n <C-o>/<><CR><C-o>d2l
nnoremap <unique> <LocalLeader>p ?<><CR>c2l
nnoremap <unique> <LocalLeader>n /<><CR>c2l

" Populate the popup menu based on the &filetype
function ChooseSnippet(filetype) abort
  let b:complete_start= [line('.'), col('.'), a:filetype]
  let l:blob = system("snippets.sh --list -- " . a:filetype)
  let l:choices = []
  for line in split(l:blob, '\n')
    let l:csv = split(line, ',')
    if len(l:csv) >= 2
      call add(l:choices, {
        \ 'word': l:csv[1],
        \ 'menu': l:csv[2],
      \ })
    endif
  endfor
  call complete(col('.'), l:choices)
  " 'complete()' inserts directly so return '' to not insert a '0'
  return ''
endfunction

" Uses the @" (yank) register to insert
function InsertSnippet() abort
  if exists('b:complete_start')
    if has_key(v:completed_item, 'word')
      let l:selection = v:completed_item['word']
      let l:len =  strlen(l:selection)

      stopinsert
      normal! hv
      call cursor(b:complete_start[0], b:complete_start[1])
      normal! x
      call cursor(b:complete_start[0], b:complete_start[1])
      let @" = system("snippets.sh " . b:complete_start[2] . " " . l:selection
        \ . " 2>/dev/null")
      setlocal paste
      execute("normal! i\<C-r>\"")
      setlocal nopaste
    endif

    unlet b:complete_start
  endif
endfunction

augroup Snippets
  autocmd!
  autocmd CompleteDone * call InsertSnippet()
augroup END

" ==============================================================================
" Extra functionality
" ==============================================================================

nnoremap <unique> <Leader>wc :echo
  \ "words: " . system('wc -w "' . expand('%') . '"')
  \ . "chars: ". system('wc -m "' . expand('%') . '"')<CR>
vnoremap <unique> <Leader>wc y:echo
  \ "words: " . system('wc -w ', @")
  \ . "chars: ". system('wc -m ', @")<CR>
" transform append
noremap  <unique> <Leader>ta :%.!sh -c 'column -t -s"$1" -o"$2"' _ 
nnoremap <unique> <Leader>tp 0yt<Bar>f<Bar>a
  \<C-r>=system("language.sh pinyin \"" . @" . '"')<CR>
  \<C-h><Bar><Esc>0j
nnoremap <unique> <Leader>rc
  \ :silent call system("    setsid reloadvim.sh --ignore-checks '"
  \. line('w0') . "' '" . line('.') . "' '" . col('.') . "' '"
  \. expand('%') . "' &")<CR>

" Knowledge Management
nnoremap <unique> <Leader>kt :edit <C-r>=system(
    \"tmux.sh run-in-new-window zet.sh tags -u 2>/dev/null")<CR><Del><CR>
nnoremap <unique> <Leader>ki :edit <C-r>=system(
    \"tmux.sh run-in-new-window zet.sh incoming -u"
    \ . " " . shellescape(expand("%:p")) . " 2>/dev/null")<CR><Del><CR>
nnoremap <unique> <Leader>ko :edit <C-r>=system(
    \"tmux.sh run-in-new-window zet.sh outgoing -u"
    \ . " " . shellescape(expand("%:p")) . " 2>/dev/null")<CR><Del><CR>
nnoremap <unique> <Leader>kl :edit <C-r>=system(
    \"tmux.sh run-in-new-window zet.sh list -u 2>/dev/null")<CR><Del><CR>

" ==============================================================================
" @TODO
" ==============================================================================
" Blank *.tex files default to 'plain' (affects which ftplugin gets used)
let g:tex_flavor = 'latex'  " See :h filetype-overrule

" Use UTF-8 if we can and env LANG didn't tell us not to
if has('multi_byte') && !exists('$LANG') && &encoding ==# 'latin1'
  set encoding=utf-8
endif
" Neovim prints random 'q' if ${TERM} is set wrong in the first login terminal
" See https://stackoverflow.com/questions/4229658
if ! has("gui_running") |  set guicursor= | endif

"set termguicolors

nnoremap <unique> <silent> <Leader>db
  \ :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name")
  \ . '> trans<' . synIDattr(synID(line("."),col("."),0),"name")
  \ . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name")
  \ . ">"<CR>

" Help FileType
augroup FileTypeHelpers
  autocmd!
  "autocmd BufNewFile,BufRead *.md   set filetype=markdown
  "autocmd bufNewFile,BufRead *.plot set filetype=gnuplot
  "autocmd bufNewFile,BufRead *.tex  set filetype=tex
augroup END
