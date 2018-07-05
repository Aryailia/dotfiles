* linker.sh - Setup so that all my dotfiles are contained in a directory and symlinks all the config files to their appropriate locations
* namedirs/* - Contains symlinks for directory shortcuts (CDPATH for cd)
* install/* - Scripts for automating some of the install process

* privates/ - A folder not included in this distribution but has a couple of files that make other things in these dotfiles work. See [linker.sh](linker.sh) for what files are contained

* bookmarks-rofi.sh - probably going to make an ncurses cli version too
* search-rofi.sh - probalby going to make an ncourses cli version too

Any symlinks are stored in git as symlinks (so like a regular files except whose contents are essentially the link to the target) so the actual contents of the symbolically linked file is not stored. 
One thing to note is that filesystems such as FAT32 do not support symlinks. Seeing the git option core.symlinks may be useful. This config does not touch it however.


# Dat vimrc
Coming Soon TM

# Tmux
Coming Sooner TM
