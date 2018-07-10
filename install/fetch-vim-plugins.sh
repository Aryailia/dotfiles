#!/bin/sh

# Prompt with default 
echo 'Enter path to vim config'
printf '(Leave blank for "$HOME/.vim"): '
read -r vimconfig
vimconfig="${vimconfig:-$HOME/.vim}"

cloneupdate() {
  target="$vimconfig/bundle/$2"
  if [ -d "$target" ]; then
    git --git-dir="$target/.git" pull origin master 
  else
    git clone "https://github.com/$1/$2.git" "$target"
  fi
}

mkdir -p "$vimconfig/autoload"

# Unlike the plugins, do not update pathogen, discrepancy cause no reason...
if [ ! -f "$vimconfig/autoload/pathogen.vim" ]; then
  wget 'https://tpo.pe/pathogen.vim' -P "$vimconfig/autoload"
fi

[ ! -d "$vimconfig/bundle" ] && 'mkdir' "$vimconfig/bundle"
cloneupdate "vimwiki" "vimwiki"
cloneupdate "godlygeek" "tabular"
cloneupdate "tpope" "vim-sleuth"
cloneupdate "tpope" "vim-surround"
#cloneupdate "tpope" "vim-markdown"

cloneupdate "rust-lang" "rust.vim"
#cloneupdate "plasticboy" "vim-markdown"
#cloneupdate "vim-pandoc" "vim-markdownfootnotes"
cloneupdate "mzlogin" "vim-markdown-toc"
