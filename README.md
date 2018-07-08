# Philosphy and workflow
Generally I try to preserve the default keybinds when possible as that is one of the most portable ways of moving to a computer owned by someone else and having a hope that one would be able to use their setup.

I choose to run tmux default when launching terminals as it buys resume functionality should I close a terminal prematurely. Just adding shift will run without tmux anyway. As a result, I created a script to combat tmux session number growing in addition to the resume feature.

I choose to use st (simple terminal) simply because of the low latency startups and running with tmux (which buys you scrollback, searching, and psuedo-clipboard) has all the necessary functionality out of the box that I need. While it does go against my philosphy of outof the box, nevertheless, I have patched in certain things which are detailed on the my fork of [st](https://www.github.com/Aryailai/st). Though to note, you can play with the font st uses as a commandline argument.


# Specifics
* linker.sh - Setup so that all my dotfiles are contained in a directory and symlinks all the config files to their appropriate locations
* namedirs/* - Contains symlinks for directory shortcuts (CDPATH for cd)
* install/* - Scripts for automating some of the install process

# privates/
A folder not included in this distribution but has a couple of files that make other things in these dotfiles work. See [linker.sh](linker.sh) for what files are contained.
Also contains:
* bookmarks.txt
* websearches.txt

# More UI-like scripts
* bookmarks-rofi.sh - probably going to make an ncurses cli version too
* search-rofi.sh - probalby going to make an ncourses cli version too

Any symlinks are stored in git as symlinks (so like a regular files except whose contents are essentially the link to the target) so the actual contents of the symbolically linked file is not stored. 
One thing to note is that filesystems such as FAT32 do not support symlinks. Seeing the git option core.symlinks may be useful. This config does not touch it however.


# Dat vimrc
Coming Soon TM

# Tmux
Coming Sooner TM

# Todo
* Comment markdown vimscript initial build of parser better (totally going to forget the next actionable items)
* Make or search for existing script to csv-ify netscape/mozilla bookmarks
* Eventually figure out if I want to proceed with the leaf block parser for markdown in awk or go back to vimscript. Or both
* Rofi launcher for different terminals maybe?
* Rofi launcher for imes
* Check if dbus launch is necessary in xinitrc on a fresh install for fcitx (runit/pulseaudio may run it, also gtk has it as a dependency)

