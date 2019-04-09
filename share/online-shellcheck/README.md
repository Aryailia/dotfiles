This is a POSIX shell script that submits code to [shellcheck](https://www.github.com/koalaman/shellcheck)'s online [website](https://www.shellcheck.net) for linting. Shellcheck is an incredibly useful tool for catch errors in shell scripts (for both POSIX and bash) and bashisms if 'sh' is selected.

Because haskell is not available for [Termux](https://www.github.com/termux/termux) (see [issue 2678](https://github.com/termux/termux-packages/issues/2678)) on Android as of March 2019, hence this tool was born.

# Dependencies
- curl
- jq (for processing json, though perhaps one could use 'awk' instead as the output of the php file is fiarly simple)

# To do
- Make '.fix' processable
- Add support for wget and perl as alternatives
- A search command for fetching the shellcheck pages for error code explanations (eg. [SC1000](https://github.com/koalaman/shellcheck/wiki/SC1000))
- Make the UI more similar to Shellcheck
- Add colouring based on the warning level

# License
Similar to Shellcheck, this is licensed under the GPLv3.
