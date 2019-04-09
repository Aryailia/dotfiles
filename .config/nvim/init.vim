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
  Plug 'vimwiki/vimwiki', { 'branch': 'dev' } ", 'on': [] } 
  ", 'for': 'markdown' }
  Plug 'tpope/vim-surround'         " Adding quotes
  Plug 'tpope/vim-scriptease'       " For the reload
  Plug 'aryailia/vim-markdown-toc'  " Table of contents woo
  Plug 'godlygeek/tabular'          " Primarily for markdown table formatting
  Plug 'kassio/neoterm'             " Terminal for vim and neovim
  Plug 'rust-lang/rust.vim'         " Rust syntax hilighting
  Plug 'jreybert/vimagit'           " Git UI
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

set nrformats-=octal  " Leading 0s are not recognised as octals
set formatoptions-=c  " Do not auto add comments
set formatoptions+=j  " Delete comment leaders when joining lines

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
"set expandtab      " Use spaces instead of tabs
set shiftwidth=2   " Indent with two spaces
"set softtabstop=2  " Insert two spaces with tab key

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
function! SaveWindowPosition()
  let b:WindowPosition = [line('w0'), line('.'), col('.')]
endfunction

function! RestoreWindowPosition()
  " 123G jumps to line 123
  " zt sets the current line as the positional top line of the window
  execute('normal! ' . (b:WindowPosition[0] + 1) . 'Gzt')
  call cursor(b:WindowPosition[1], b:WindowPosition[2])
endfunction

" Key rebindings `:help index`
" http://vimdoc.sourceforge.net/htmldoc/vimindex.html
" Movement
nnoremap j         gj
nnoremap k         gk
nnoremap <C-j>     j
nnoremap <C-k>     k

nnoremap <leader>fn :call FootnoteViewToggle()<CR>
nnoremap <silent> <Leader>db
  \ :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name")
  \ . '> trans<' . synIDattr(synID(line("."),col("."),0),"name")
  \ . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name")
  \ . ">"<CR>
nnoremap <leader>s :write<CR>

" #Clipboard stuff
" Sync Clipboard, not sure why it needs double newline
nnoremap <leader>qc
  \ :if has('clipboard') \| let @* = @" \| let @+ = @" \| endif<CR><CR>

vmap <leader>c y:call system('clipboard.sh --write', @")<CR>\qc
nmap <leader>c :silent call system("clipboard.sh --write", @")<CR>\qc
nnoremap <leader>v :let @" = system('clipboard.sh --read')<CR>p
nnoremap <leader>V :let @" = system('clipboard.sh --read')<CR>P

vnoremap <leader>y "*y :let @+ = @*<CR>
nnoremap <leader>p "*p
nnoremap <leader>P "*P

" Select the same selection again after doing an indent
vnoremap > >gv
vnoremap < <gv

noremap <leader>rn :set relativenumber!<CR>
noremap <leader>rc
  \ :Runtime<CR>
  \ :call SaveWindowPosition()<CR>
  \ :source $MYVIMRC<CR>
  \ :echom 'Reload' . $MYVIMRC<CR>
  \ :redraw<CR>
  \ :call RestoreWindowPosition()<CR>
noremap <leader>ts
  \ :if exists("g:syntax_on")<bar>syntax off<bar>
  \ else<bar>syntax on<bar>endif<CR>
noremap <leader>hg :call PrintHighlightGroup()<CR>

" Likely to change very soon
noremap <leader><tab> :Tab /\|<CR>
noremap <leader>rs :write! !parsemarkdown.awk<CR>
nnoremap <F11> :call FollowCursorLink()<CR>
nnoremap <F12> :call FollowBack()<CR>

" Mirrors
nmap <F1> \s
nmap <C-s> \s
imap <F1> <C-o>\s
imap <C-s> <C-o>\s
vmap <C-c> \c
nmap <C-p> \v

" Build(), Run(), Lint() are defined in filetype for customisation
noremap <silent> <Leader>1 :call Build()<CR>
noremap <silent> <Leader>2 :call Run()<CR>
noremap <silent> <Leader>3 :vertical T clear<CR>
noremap <silent> <Leader>4 :vertical T exit<CR>:redraw<CR>
noremap <silent> <Leader>l :call Lint()<CR>
imap <silent> <F1> <C-o>\1
imap <silent> <F2> <C-o>\2
imap <silent> <F3> <C-o>\3
imap <silent> <F4> <C-o>\3
"nmap <silent> あ a

augroup vimrc
  autocmd!
  autocmd! BufWritePost $MYVIMRC normal \rc
augroup END
