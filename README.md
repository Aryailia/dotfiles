# Philosphy and workflow
## Target
- Linux VMs (though note that shared folder in VirtualBox are read-only, since this relies on symlinks from 'shared/', the installation may fail)
- Window 7 with Git. Curious how far I can get without Cygwin or Putty.
- Raspberry Pi 3
- Android (Termux). Writing on the go with a keyboard.
- MacOS (Currently do not have)

Cannot use this on iOS (iPad/iPhone) since Apple's term of service prohibits downloading 3rd party code to run unless it is Safari (citation needed). According to Mozila, [Firefox does support the native iOS extension ecosystem](https://developer.mozilla.org/en-US/docs/Mozilla/Firefox_for_iOS), which I am not exactly sure is what. Unsure of other browsers do something similar. [OpenTerm for iOS](https://github.com/louisdh/openterm) is something to look into (only available for iOS 11). OpenTerm uses its own made script called Cub instead Bashscript.

Not sure if I will ever be interested in getting the Windows Subsystem for Linux (WSL) working on Win10.

# Design Philosphy

Generally I try to preserve the default keybinds when possible as that is one of the most portable ways of moving to a computer owned by someone else and having a hope that one would be able to use their setup.

I choose to run tmux default when launching terminals as it buys resume functionality should I close a terminal prematurely. Just adding shift will run without tmux anyway. As a result, I created a script to combat tmux session number growing in addition to the resume feature.

## share/
These are all scripts that I broke off into their seperate projects so that other people could contribute to them or download them exclusively. These are less personally customised to my workflow so should be useful as standalones. These scripts are then appropriately symlinked to the '.config/scripts' folder.

These are included as a git subtree. This was done so that it is easy to pull and maintain. To push to these subfolders: (see [git subtrees on atlassian](https://www.atlassian.com/blog/git/alternatives-to-git-submodule-git-subtree))

TODO add commands

# Installation
```sh
cd ~  # or wherever you would like to place the dotfiles folder
git clone https://github.com/Aryailia/dotfiles
dotfiles/linker.sh
```

Folders/files to take note of are:
* linker.sh - Setup so that all my dotfiles are contained in a directory and symlinks all the config files to their appropriate locations
* .config/named_direcotires/* - Contains symlinks for directory shortcuts (could be used for CDPATH for cd)
* install/* - Scripts for automating some of the install process
* .config/scripts/shortcuts.sh - Creates the shortcuts (currently just for `c` and `vifm` from '.config/shortcutsrc')
* .config/shortcutsrc - List of directory shortcuts
* .config/aliasrc - List of shell alises that is sorced by any shells I might use

# .environment/
A folder not included in this distribution but has a couple of files that make other things in these dotfiles work. See [linker.sh](linker.sh) for what files are contained.
Also contains:
* bookmarks.csv
* websearches.csv



# Description of scripts
* browser.sh


# Dat vimrc
Coming Soon TM

# Tmux
Coming Sooner TM

# Todo
* Comment markdown vimscript initial build of parser better (totally going to forget the next actionable items)
* Eventually figure out if I want to proceed with the leaf block parser for markdown in awk or go back to vimscript. Or both

