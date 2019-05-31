" the `autocmd!` deletes previous bindings if sourced again
" Not sure if this even helps but to help when sourcing for editing
mapclear
mapclear!

"execute pathogen#infect()
"syntax on
"filetype plugin indent on

" Automatically executes `filetype plugin indent on` and `syntax enable`
" :PlugInstall to install
call plug#begin('~/.vim/extra')
  " VimWiki for markdown interlinks, (probably make my own, too much bloat)
  "Plug 'vimwiki/vimwiki', { 'branch': 'dev' } ", 'on': [] }
  ", 'for': 'markdown' }
  "Plug 'tpope/vim-scriptease'       " For the reload
  Plug 'tpope/vim-unimpaired'       " Setting toggles, back/next nav shortcuts
  Plug 'tpope/vim-surround'         " Adding quotes
  Plug 'aryailia/vim-markdown-toc'  " Table of contents woo
  Plug 'godlygeek/tabular'          " Primarily for markdown table formatting
  Plug 'kassio/neoterm'             " Terminal for vim and neovim
  Plug 'rust-lang/rust.vim'         " Rust syntax hilighting
  Plug 'jreybert/vimagit'           " Git UI
  Plug 'rlue/vim-barbaric'          " Swap IME on insert mode
call plug#end()

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
set formatoptions-=c  " Do not auto add comments
set ignorecase

set number " setting relativenumber was kiling performance
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
" yuvim, CYK input
let g:ywvim_ims=[
  \['py', '拼音', 'pinyin.ywvim'],
  \['zm', '郑码', 'zhengma.ywvim'],
  \['zy', '注音', 'zhuyin.ywvim'],
\]

let g:ywvim_py = { 'helpim':'py', 'gb':0 }

let g:ywvim_zhpunc = 1
let g:ywvim_listmax = 5
let g:ywvim_esc_autoff = 0
let g:ywvim_autoinput = 0
let g:ywvim_intelligent_punc=1
let g:ywvim_circlecandidates = 1
let g:ywvim_helpim_on = 0
let g:ywvim_matchexact = 0
let g:ywvim_chinesecode = 1
let g:ywvim_gb = 0
let g:ywvim_preconv = 'g2b'
let g:ywvim_conv = ''
let g:ywvim_lockb = 1

" Vimwiki
let g:vimwiki_ext2syntax = { '.md': 'markdown', '.wiki': 'media' }
" TODO: Have not really figured this out
let g:vimiwki_list = [
  \ {'path': '~/wiki/', 'syntax': 'markdown', 'ext': '.md'},
  \ {'path': '~/blog/test/', 'auto_toc': 1, 'index': 'index.wiki'}
\]

" Vim Markdown Table of Contents
let g:vmt_cycle_list_item_markers = 1
let g:vmt_fence_hidden_markdown_style = ''

let g:maplocalleader = ','

" Rebinds, use unique everywhere so it yells at me if I duplicate a keybind
" Disable Ex mode (can still use gQ)
nnoremap <unique> Q <Nul>

" Clear whitespace
nnoremap <unique> <leader>w :%s/\s\+$//g<CR>

" Stuff modelled after tpope's vim-unimpared
" Spellcheck with chooseable locale, 'o' for othography
nnoremap <silent> <unique> yoo
  \ :if &spell<Bar>
    \setlocal nospell<Bar>
  \else<Bar>
    \execute 'setlocal spell spelllang=' . input('spelllang=', 'en_gb')<Bar>
  \endif<CR>

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
nmap <unique> <C-s> <Leader>s
imap <unique> <C-s> <C-o><Leader>s

" Clipboard
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

" Build(), Run(), Lint() are defined in filetype for customisation
noremap <unique> <silent> <Leader>1 :call Build()<CR>
noremap <unique> <silent> <Leader>2 :call Run()<CR>
noremap <unique> <silent> <Leader>3 :vertical T clear<CR>
noremap <unique> <silent> <Leader>4 :vertical T exit<CR>:redraw<CR>
noremap <unique> <silent> <Leader>l :call Lint()<CR>
imap <unique> <silent> <F1> <C-o><Leader>1
imap <unique> <silent> <F2> <C-o><Leader>2
imap <unique> <silent> <F3> <C-o><Leader>3
imap <unique> <silent> <F4> <C-o><Leader>3


" Plugin Development Debugging stuff
nnoremap <leader>fn :call FootnoteViewToggle()<CR>
nnoremap <unique> <silent> <Leader>db
  \ :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name")
  \ . '> trans<' . synIDattr(synID(line("."),col("."),0),"name")
  \ . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name")
  \ . ">"<CR>
noremap <leader>hg :echo "yo"<CR>
noremap <unique> <leader><tab> :Tab /\|<CR>
noremap <unique> <leader>rs :write! !parsemarkdown.awk<CR>
nnoremap <unique> <F11> :call FollowCursorLink()<CR>
nnoremap <unique> <F12> :call FollowBack()<CR>



" Vimrc garbage
function! SaveWindowPosition()
  let b:WindowPosition = [line('w0'), line('.'), col('.')]
endfunction

function! RestoreWindowPosition()
  " 123G jumps to line 123
  " zt sets the current line as the positional top line of the window
  execute('normal! ' . (b:WindowPosition[0]) . 'Gzt')
  call cursor(b:WindowPosition[1], b:WindowPosition[2])
endfunction

nnoremap <unique> <Leader>rc
  \ :silent call system("setsid reloadvim.sh '"
  \. line('w0') . "' '" . line('.') . "' '" . col('.') . "' '"
  \. expand('%') . "'")<CR>
"noremap <unique> <Leader>rc
"  \ :call SaveWindowPosition()<CR>
"  \:source $MYVIMRC<CR>
"  \:Runtime after/**/*<CR>
"  \:echom 'Reload' . $MYVIMRC<CR>
"  \:redraw<CR>
"  \:call RestoreWindowPosition()<CR>
nnoremap <unique> <leader>ts
  \ :if exists("g:syntax_on")<Bar>syntax off<Bar>
  \else<Bar>syntax on<Bar>endif<CR>

augroup vimrc
  autocmd!
  autocmd! BufWritePost $MYVIMRC normal <Leader>rc
augroup END
