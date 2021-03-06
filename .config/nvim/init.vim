" the `autocmd!` deletes previous bindings if sourced again
" Not sure if this even helps but to help when sourcing for editing
mapclear
mapclear!

"execute pathogen#infect()
"syntax on
"filetype plugin indent on

" Automatically executes `filetype plugin indent on` and `syntax enable`
" :PlugInstall to install
call plug#begin($VIMDOTDIR . '/package')
  Plug 'tpope/vim-unimpaired'       " Setting toggles, back/next nav shortcuts
  Plug 'tpope/vim-surround'         " Adding quotes
  Plug 'aryailia/vim-markdown-toc'  " Table of contents woo
  Plug 'godlygeek/tabular'          " Primarily for markdown table formatting
  Plug 'kassio/neoterm'             " Terminal for vim and neovim
  Plug 'rlue/vim-barbaric'          " Swap IME on entering insert mode

  "Plug 'dpelle/vim-LanguageTool'    " LanguageTool
  "Plug 'rhysd/vim-grammarous'       " LanguageTool. More async but older 
  Plug 'ap/vim-css-color'           " Color hex colour values
  Plug 'rust-lang/rust.vim'         " Rust syntax highlighting
  Plug 'habamax/vim-asciidoctor'    " Stock adoc syntax highlighting is slow
  Plug 'prabirshrestha/vim-lsp'     " Language-Server Protocol client
  Plug 'prabirshrestha/asyncomplete.vim'     " Show omni menu while typing
  Plug 'prabirshrestha/asyncomplete-lsp.vim' " Source from vim-lsp
call plug#end()

"colorscheme base16-unikitty-light
"colorscheme base16-summerfruit-light
"colorscheme base16-one-light
"colorscheme base16-shapeshifter
"set termguicolors

" autocmd BufNewFile,BufRead *.md set filetype=markdown

" General
set nocompatible
set foldmethod=manual
set bg=light          " Readable on light background
"hi Visual term=reverse cterm=reverse guibg=Grey
highlight Visual cterm=NONE ctermbg=LightYellow ctermfg=NONE

" Use UTF-8 if we can and env LANG didn't tell us not to
if has('multi_byte') && !exists('$LANG') && &encoding ==# 'latin1'
  set encoding=utf-8
endif
" Neovim prints random 'q' if ${TERM} is set wrong in the first login terminal
" See https://stackoverflow.com/questions/4229658
if ! has("gui_running")
  set guicursor=
endif

autocmd FileType * setlocal formatoptions-=cro formatoptions+=j
set nrformats-=octal  " Leading 0s are not recognised as octals
set formatoptions+=j  " Delete comment leaders when joining lines
set formatoptions-=c  " Do not auto-wrap comments when exceeding textwidth
set formatoptions-=o  " Do not auto add comments on normal 'o' or 'O'
set formatoptions-=r  " Do not auto add comments on <Enter>
set ignorecase

set number " setting relativenumber was killing performance
syntax sync minlines=256  " improve syntax performance
set nocursorcolumn
set nocursorline
set colorcolumn=81  " Archaic 80-character width, keep to before the line
highlight ColorColumn ctermfg=red ctermbg=cyan guibg=cyan

" New vertical and horizontal splits open down and right respectively by default
set splitbelow
set splitright

" The all-important default indent settings; filetypes to tweak
set autoindent     " Use indent of previous line on new lines
set expandtab      " Use spaces instead of tabs, use C-v to enter tabs
set shiftwidth=2   " Indent with two spaces
"set softtabstop=2  " Insert two spaces with tab key
highlight HighlightedWhitespace ctermbg=Grey guibg=Grey
call matchadd('HighlightedWhitespace', '\t')
call matchadd('HighlightedWhitespace', '\s\+$')


" Wildmenu settings; see also plugin/wildignore.vim
set wildmenu                " Use wildmenu
set wildmode=list:longest   " Tab press completes and lists
silent! set wildignorecase  " Case insensitive, if supported


" Plugin Settings
let g:mapleader = '\'
let g:maplocalleader = '	'

" Vim Markdown Table of Contents
let g:vmt_cycle_list_item_markers = 1
let g:vmt_fence_hidden_markdown_style = ''

" Blank *.tex files default to 'plain' (affects which ftplugin gets used)
let g:tex_flavor = 'latex'  " See :h filetype-overrule
" .tex files need a `\begin{document}`-`\end{document}` block to be detected
"autocmd BufRead,BufNewFile *.tex set filetype=plaintex

" ==============================================================================
" General Bindings
" ==============================================================================
" Use unique everywhere so it yells at me if I duplicate a keybind
" Disable Ex mode (can still use gQ)
nnoremap <unique> Q <Nul>
" Clean whitespace
nnoremap <unique> <leader>w :%s/\s\+$//g<CR>

" Stuff modelled after tpope's vim-unimpared
" Spellcheck with selectable locale, 'o' for orthography
nnoremap <silent> <unique> yoo
  \ :if &spell<Bar>
    \setlocal nospell<Bar>
  \else<Bar>
    \execute 'setlocal spell spelllang=' . input('spelllang=', 'en_gb')<Bar>
  \endif<CR>
" 't' for -tax
nnoremap <unique> <leader>yot
  \ :if exists("g:syntax_on")<Bar>syntax off<Bar>
  \else<Bar>syntax on<Bar>endif<CR>

" 'j' and 'k' move visual lines, Ctrl versions to move the original real lines
nnoremap <unique> j    gj
vnoremap <unique> j    gj
nnoremap <unique> k    gk
vnoremap <unique> k    gk
nnoremap <unique> <C-j> j
vnoremap <unique> <C-j> j
nnoremap <unique> <C-k> k
vnoremap <unique> <C-k> k

" Select the same selection again after doing an indent
vnoremap <unique> > >gv
vnoremap <unique> < <gv
"nmap <silent> あ a

" Saving
nnoremap <unique> <leader>s :write<CR>
nnoremap <unique> <C-s> :write<CR>
inoremap <unique> <C-s> <C-o>:write<CR>

" Misc
nnoremap <unique> <Leader>wc :echo
  \ "words: " . system('wc -w "' . expand('%') . '"')
  \ . "chars: ". system('wc -m "' . expand('%') . '"')<CR>
vnoremap <unique> <Leader>wc y:echo
  \ "words: " . system('wc -w ', @")
  \ . "chars: ". system('wc -m ', @")<CR>
noremap <unique> <Leader>ta<Tab> :%Tab /\|<CR>
nnoremap <unique> <Leader>tp 0yt<Bar>f<Bar>a
  \<C-r>=system("language.sh pinyin \"" . @" . '"')<CR>
  \<C-h><Bar><Esc>0j
noremap <unique> <Leader>t, :Tab /\,<CR>
nnoremap <unique> <Leader>rc
  \ :silent call system("    setsid reloadvim.sh --ignore-checks '"
  \. line('w0') . "' '" . line('.') . "' '" . col('.') . "' '"
  \. expand('%') . "' &")<CR>

" ==============================================================================
" Clipboard
" ==============================================================================
" Consider trick of `if has("clipboard") @+ = @* = @"` ?
nnoremap <unique> <Leader>c :silent call system("clipboard.sh --write", @")<CR>
vnoremap <unique> <Leader>c y:call system('clipboard.sh --write', @")<CR>gv
inoremap <unique> <C-p>
  \ <C-o>:setlocal paste<CR>
  \<C-o>:let @" = system('clipboard.sh --read')<CR><C-r>"
  \<C-o>:setlocal nopaste<CR>

nmap <unique> <Leader>p a<C-p><Esc>
nmap <unique> <Leader>P i<C-p><Esc>
nmap <unique> <Leader>v a<C-p><Esc>
nmap <unique> <Leader>V i<C-p><Esc>
nmap <unique> <C-p> <Leader>p
vmap <unique> <C-c> <Leader>c

" Visual-mode select the next URI if valid URL or if path to existing file
nmap <unique> <C-l> <Plug>SelectNextURI
imap <unique> <C-l> <C-o><Plug>SelectNextURI
vmap <unique> <C-l> <Esc><Plug>SelectNextURI

" Cannot have <CR> and <C-m> mapped to different things (99% sure)
"inoremap <unique> <C-m> <C-o>o

" ==============================================================================
" Compilation
" ==============================================================================
" Build(), Run(), Lint() are defined in filetype for customisation
function! RunCmdlineOverload(prefix, notfound, found)
  let l:overload = searchpos('\m' . a:prefix, 'nw')
  if l:overload[0] == 0
    call a:notfound()
  else
    let l:cmd = getline(l:overload[0])
    let l:cmd = substitute(l:cmd, a:prefix, '', '')
    let l:cmd = substitute(l:cmd, '%', expand('%'), '')
    call a:found(l:cmd)
  endif
endfunction


function! Lint()
  "ALELint
endfunction

noremap <unique> <silent> <Leader>1 :call BuildBackground()<CR>
noremap <unique> <silent> <Leader>2 :call Build()<CR>
noremap <unique> <silent> <Leader>3 :call Run()<CR>
noremap <unique> <silent> <Leader>4 <C-w><C-w>G<C-w><C-w>
noremap <unique> <silent> <Leader>5 :vertical Tclose!<CR>
noremap <unique> <silent> <Leader>l :call Lint()<CR>
imap <unique> <silent> <F1> <C-o><Leader>1
imap <unique> <silent> <F2> <C-o><Leader>2
imap <unique> <silent> <F3> <C-o><Leader>3
imap <unique> <silent> <F4> <C-o><Leader>4
imap <unique> <silent> <F5> <C-o><Leader>5

" Populate the popup menu based on the &filetype
function ChooseSnippet() abort
  let b:complete_start= [line('.'), col('.')]
  let l:blob = system("snippets.sh --list -- " . &filetype)
  let l:choices = []
  for line in split(l:blob, '\n')
    let l:csv = split(line, ',')
    if len(l:csv) >= 2
      call add(l:choices, {
        \ 'word': l:csv[0],
        \ 'menu': l:csv[1],
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
      normal! v
      call cursor(b:complete_start[0], b:complete_start[1])
      normal! x
      let @" = system("snippets.sh " . &filetype . " " . l:selection)
      "startinsert does not seem to work
      normal! P
    endif

    unlet b:complete_start
  endif
endfunction

" Automatically detect from &filetype
inoremap <unique> <LocalLeader><Tab> <C-r>=ChooseSnippet()<CR>
" Give pop-up list (needs tmux)
inoremap <unique> <LocalLeader>q <C-o>:silent read !snippets.sh -t<CR>
" Move cursor and replace placeholder '<>'
inoremap <unique> <LocalLeader>p <C-o>?<><CR><C-o>d2l
inoremap <unique> <LocalLeader>n <C-o>/<><CR><C-o>d2l
nnoremap <unique> <LocalLeader>p ?<><CR>c2l
nnoremap <unique> <LocalLeader>n /<><CR>c2l

augroup Snippets
  autocmd!
  autocmd CompleteDone * call InsertSnippet()
augroup END

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

nnoremap <unique> <Leader>;l :call ListUrls()<CR>
nnoremap <unique> yo; :lclose<CR>

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

nnoremap <unique> gr <plug>(lsp-references)
nnoremap <unique> gt <plug>(lsp-type-definition)
nnoremap <unique> gi <plug>(lsp-implementation)
nnoremap <unique> gd <plug>(lsp-definition)
nnoremap <unique> [g <plug>(lsp-previous-diagnostic)
nnoremap <unique> ]g <plug>(lsp-next-diagnostic)
nnoremap <unique> K <plug>(lsp-hover)

" Spelling
nnoremap <unique> <Leader>sus :set spelllang=en_US,cjk<CR>
nnoremap <unique> <Leader>sen :set spelllang=en_GB,cjk<CR>

let g:asyncomplete_auto_completeopt = 0
let g:lsp_auto_enable = 0  " Do not auto-start LSP servers on file open

" ==============================================================================
" Register the LSP servers
if executable('rls')
  " Have to repeat install for different streams (stable, nightly, etc.)
  " rustup add component rls
  au User lsp_setup call lsp#register_server({
    \ 'name': 'rls',
    \ 'cmd': { server_info->['rls'] },
    \ 'workspace_config': {'rust': {'clippy_preference': 'on' }},
    \ 'whitelist': ['rust'],
  \ })

  ""
  "au User lsp_setup call lsp#register_server({
  "  \ 'name': 'rust-analyzer',
  "  \ 'cmd': { server_info->['rust-analyzer'] },
  "  \ 'whitelist': ['rust'],
  "\ })
endif

if executable('vim-language-server')
  " npm install --global vim-languageserver
  augroup LspVim
    autocmd!
    autocmd User lsp_setup call lsp#register_server({
      \ 'name': 'vim-language-server',
      \ 'cmd': { server_info->['vim-language-server', '--stdio'] },
      \ 'whitelist': ['vim'],
      \ 'initialization_options': {
        \ 'vimruntime': $VIMRUNTIME,
        \ 'runtimepath': &rtp,
      \ }
    \ })
endif

if executable('javascript-typescript-stdio')
  " sudo npm install --global vscode-css-languageserver-bin
  au User lsp_setup call lsp#register_server({
    \ 'name': 'sourcegraph-typescript-javascript',
    \ 'cmd': { server_info->['javascript-typescript-stdio'] },
    \ 'whitelist': ['javascript', 'typescript', 'typescript.tsx'],
  \ })
endif

" sudo npm install --global vscode-html-langserver-bin

if executable('css-languageserver')
  " sudo npm install --global vscode-css-languageserver-bin
  au User lsp_setup call lsp#register_server({
    \ 'name': 'vscode-css',
    \ 'cmd': { server_info->['css-languageserver', '--stdio'] },
    \ 'whitelist': ['css', 'less', 'sass'],
  \ })
endif

" ==============================================================================
" vim-lsp enable/disable/init stuff
function! ToggleVimLsp() abort
  if !exists("g:lsp_auto_enable")
      \|| (exists("b:vim_lsp_is_enabled") && b:vim_lsp_is_enabled == 1)
    call StopVimLsp()
  else
    call StartVimLsp()
  endif
endfunction

" This does not clear diagnostic or error messages
function! StopVimLsp() abort
  let b:vim_lsp_is_enabled = 0
  LspStopServer
  setlocal omnifunc=
  setlocal signcolumn=auto
  if exists('+tagfunc') | setlocal tagfunc= | endif
  call lsp#disable()
endfunction

function! StartVimLsp() abort
  let b:vim_lsp_is_enabled = 1
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes
  if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
  call lsp#enable()
endfunction

function! s:on_lsp_buffer_enabled() abort
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes
  if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
endfunction

" Runs when opening a buffer
augroup lsp_install
  au!
  autocmd User lsp_buffer_enabled call StartVimLsp()
  "autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END


" Linters set in filetypes (or detected automatically)
" LanguageTool integration only seems to execute on manual :ALELint
"let b:ale_languagetool_executable = 'java'
"let b:ale_languagetool_options = '-jar ${XDG_DATA_HOME}/LanguageTool-4.7
"  \/languagetool-commandline.jar -l zh'

" ==============================================================================
" Temporary Plugin Development Stuff
" ==============================================================================
nnoremap <leader>fn :call FootnoteViewToggle()<CR>
nnoremap <unique> <silent> <Leader>db
  \ :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name")
  \ . '> trans<' . synIDattr(synID(line("."),col("."),0),"name")
  \ . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name")
  \ . ">"<CR>
noremap <unique> <Leader>rs :write! !parsemarkdown.awk<CR>
nnoremap <unique> <F11> :call FollowCursorLink()<CR>
nnoremap <unique> <F12> :call FollowBack()<CR>

" ==============================================================================
" Snippets
" ==============================================================================
" The dashes
inoremap <unique> <LocalLeader>em —
inoremap <unique> <LocalLeader>en –
inoremap <unique> <LocalLeader>fig ‒
" Note that '~' is nbps in latex.
" Insert two full-width spaces. NOTE: The following have whitespace after
inoremap <unique> <LocalLeader>~ 　　
inoremap <unique> ，～ 　　
