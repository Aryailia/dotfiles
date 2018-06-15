#!/bin/bash

function cloneupdate() {
  if [ -d "$2" ]; then
    git --git-dir="$2/.git" pull origin master 
  else
    git clone "https://github.com/$1/$2"
  fi
}

# Prompt with default 
read -e -p "Default vim config directory? " -i "$HOME/.vim/" VIMCONFIG

mkdir -p "$VIMCONFIG/autoload"
cd "$VIMCONFIG/autoload"
[ -f "pathogen.vim" ] || wget 'https://tpo.pe/pathogen.vim'

[ ! -d "$VIMCONFIG/bundle" ] && mkdir "$VIMCONFIG/bundle"
cd "$VIMCONFIG/bundle"
#cloneupdate "vimwiki" "vimwiki"
cloneupdate "godlygeek" "tabular"
cloneupdate "farmergreg" "vim-lastplace"
cloneupdate "tpope" "vim-sleuth"

cloneupdate "rust-lang" "rust.vim"
cloneupdate "plasticboy" "vim-markdown"
cloneupdate "mzlogin" "vim-markdown-toc"
