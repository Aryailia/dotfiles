" the `autocmd!` deletes previous bindings if sourced again
" Not sure if this even helps but to help when sourcing for editing
mapclear
mapclear!

"execute pathogen#infect()
"syntax on
"filetype plugin indent on

" Automatically executes `filetype plugin indent on` and `syntax enable`
" :PlugInstall to install
call plug#begin('~/.config/nvim/extra')
  Plug 'tpope/vim-unimpaired'       " Setting toggles, back/next nav shortcuts
  Plug 'tpope/vim-surround'         " Adding quotes
  Plug 'aryailia/vim-markdown-toc'  " Table of contents woo
  Plug 'godlygeek/tabular'          " Primarily for markdown table formatting
  Plug 'kassio/neoterm'             " Terminal for vim and neovim
  Plug 'rlue/vim-barbaric'          " Swap IME on entering insert mode

  "Plug 'dpelle/vim-LanguageTool'    " Cannot figure out how to use ale for this
  " Microsoft's Language Server Protocol, for autocompletion etc.
  Plug 'rust-lang/rust.vim'         " Rust syntax hilighting
  Plug 'dense-analysis/ale'         " Autocomplete, LSP integration, and linting
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

" Use UTF-8 if we can and env LANG didn't tell us not to
if has('multi_byte') && !exists('$LANG') && &encoding ==# 'latin1'
  set encoding=utf-8
endif
" Neovim prints random 'q' if ${TERM} is set wrong in the first login terminal
" See https://stackoverflow.com/questions/4229658
if ! has("gui_running")
  set guicursor=
endif

set nrformats-=octal  " Leading 0s are not recognised as octals
set formatoptions+=j  " Delete comment leaders when joining lines
"set formatoptions-=r  " Do not auto add comments on <Enter>
set formatoptions-=c  " Do not auto-wrap comments when exceeding textwidth
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
let g:maplocalleader = ','

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
noremap <unique> <Leader>t<Tab> :Tab /\|<CR>
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
  ALELint
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

" ==============================================================================
" Language Server Protocol (LSP) and 'ale' plugin
" ==============================================================================
" Linters set in filetypes (or detected automatically)
nnoremap <unique> <Leader>tl :ALEToggle<CR>
let g:ale_lint_on_text_changed = 'never'  " Text change in insert or normal mode
let g:ale_lint_on_insert_leave = 1        " Enter/leave insert mode
let g:ale_lint_on_save = 1                " on :Write
let g:ale_lint_on_enter = 0               " When entering the file
let g:ale_virtualtext_cursor = 1          " Neovim: Display linter text on side


" LanguageTool integration only seems to execute on manual :ALELint
let b:ale_languagetool_executable = 'java'
let b:ale_languagetool_options = '-jar ${XDG_DATA_HOME}/LanguageTool-4.7
  \/languagetool-commandline.jar -l zh'
"let g:ale_linters = { 'tex': ['languagetool','proselint'] }
"let g:ale_linter_aliases = { 'tex': ['tex', 'text']}
"let g:ale_linters = {'tex': ['languagetool'], 'text': ['languagetool']}
"let g:ale_linters_explicit = 0

call ale#linter#Define('css', {
  \ 'name':       'vscode-css',
  \ 'lsp':        'stdio',
  \ 'executable': 'css-languageserver',
  \ 'command':    '%e --stdio',
  \ 'project_root': '.',
\ })
call ale#linter#Define('hmtl', {
  \ 'name':       'vscode-css',
  \ 'lsp':        'stdio',
  \ 'executable': 'css-languageserver',
  \ 'command':    '%e --stdio',
  \ 'project_root': '.',
\ })

" Auto complete
let g:ale_completion_enabled = 1
set omnifunc=ale#completion#OmniFunc
inoremap <expr> <Tab> pumvisible()
  \?(empty(v:completed_item)?"\<C-n>":"\<C-y>")
  \:"\<Tab>"
" Avoid completing with only one item. Causes problems when deleting
set completeopt=menu,menuone,preview,noinsert,noselect

" Keymaps
nnoremap <unique> <silent> K :ALEHover<CR>
nnoremap <unique> <silent> gd :ALEGoToDefinition<CR>
nnoremap <unique> <silent> <Leader>rn :ALERename<CR>
nnoremap <unique> <Leader>sus :set spelllang=en_US,cjk<CR>
nnoremap <unique> <Leader>sen :set spelllang=en_GB,cjk<CR>

" UI
highlight link ALEWarningSign Todo
highlight link ALEErrorSign WarningMsg
highlight link ALEVirtualTextWarning Todo
highlight link ALEVirtualTextInfo Todo
highlight link ALEVirtualTextError WarningMsg
highlight ALEError guibg=None
highlight ALEWarning guibg=None
let g:ale_sign_error = "✖"
let g:ale_sign_warning = "⚠"
let g:ale_sign_info = "ℹ"
let g:ale_sign_hint = "➤"

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
