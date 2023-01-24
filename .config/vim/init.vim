" Vim is originally designed with to get most of its extra functionality by
" integrating with external utilties and not through plugins. You do this via
" vim filters (e.g. normal mode ':.!sort'), execu

" e.g. I tabularise with the 'column' (see ':nmap' for '\ta' or <Leader>ta)

" However, neither POSIX executables nor short shellscript do not provide
" - syntax highlighting (better and/or more filetypes than default vim)
" - LSP
" - Async api (jobstart()) requires a non-trival amount of code
"  - vim has ':!start' syntax which is very short
" - Terminal api differs between vim and neovim because neovim got it first

" highlighting for a large range of programming languages. Also the vanilla
" terminal and async API differs between vim and neovim.

" We want progressive enhancement (web terminology). That is, you build
" for the least featured device (vim forks and/or version), and feature gate
" functionality (i.e. if statements)

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
" Need this for vim, but not neovim
set directory    =$XDG_CACHE_HOME/vim/swap,/tmp
set backupdir    =$XDG_CACHE_HOME/vim/backup,/tmp
if has('nvim')
  set viminfofile=$XDG_CACHE_HOME/vim/nviminfo
else
  set viminfofile=$XDG_CACHE_HOME/vim/viminfo
endif
set runtimepath  =$VIM,$XDG_CONFIG_HOME/vim,$VIM,$VIMRUNTIME,$XDG_CONFIG_HOME/vim/after
let g:vimdotdir  =$XDG_CONFIG_HOME . "/vim"

"" Let '$VIMINIT' handle this
"let $MYVIMRC="$XDG_CONFIG_HOME/vim/init.vim"
"" 'runtimepath' sets this
"let g:netrw_home=/dev/null

if has("syntax") && !has("nvim-0.8") | syntax enable | endif
filetype plugin indent on

let mapleader = '\'
let maplocalleader = '	'

" the `autocmd!` deletes previous bindings if sourced again
" Not sure if this even helps but to help when sourcing for editing
mapclear | mapclear! | mapclear <buffer> | mapclear! <buffer>

" Automatically executes `filetype plugin indent on` and `syntax enable`
" @TODO: put specific commit hashs for improved security
" :PlugInstall to install
if filereadable(g:vimdotdir . '/autoload/plug.vim')
  call plug#begin(g:vimdotdir . '/package')
    Plug 'tpope/vim-surround'              " Adding quotes
    Plug 'kassio/neoterm'                  " Terminal for vim and neovim
    Plug 'skywind3000/asyncrun.vim'        " Run scripts in the background async
    Plug 'ap/vim-css-color'                " Color hex colour values

    Plug 'habamax/vim-asciidoctor'         " Stock adoc syntax highlight is slow
    Plug 'nvim-treesitter/nvim-treesitter' " Syntax parser, highlight, and LSP
    Plug 'nvim-treesitter/playground'      " For viewing the tree-sitter AST
    Plug 'prabirshrestha/vim-lsp'          " Language-Server Protocol client
  call plug#end()
endif

" I put most of the configuration in the after/plugin directory
" Vim loads this file first, then everything except 'after', then 'after'
" See :h runtime for more information
