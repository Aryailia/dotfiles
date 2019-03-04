# Style Guide for Shell Scripts
## Some references
- [Rich's sh tips for robust portability](https://etalabs.net/sh_tricks)
  * [dirname basename vs parameter expansion edge cases](https://unix.stackexchange.com/questions/253524/)
- [Google's style guide is a reasonable reference](https://google.github.io/styleguide/shell.xml)
- Greg wiki

## Personal style guide
Recommendation, reason(s), and example if pertinent

### On avoiding bash
- Use sh/dash
  * POSIX compliance, portability
- Use two spaces for indents
  * Portability
- Use awk when dash is not cutting it (eg. Array usage)
  * For all those who do not use bash, maybe one day, I will join them
- TODO: On a substitute for process substitution
- TODO: On forking jobs
- Use aboslute urls for non-dash commands, both for GNU utilities and external scripts/programs
  * Security, [Apple's guide to secure shell scripting](https://developer.apple.com/library/archive/documentation/OpenSource/Conceptual/ShellScripting/ShellScriptSecurity/ShellScriptSecurity.html)
  + `/bin/cp a.txt b.txt`

### Larger
- Always keep to 80 character limit
  + Introducing variables can be helpful
  + Backslash for linebreaking
  + Can group commands with {} or ()
- Header format: Shebang, parameter description, description of purpose, have help dump near top
  * Second-line indent is to aid in setting automatic indentation as well as for clarity
- (Mimic functional coding style of breaking up multi-line commands)

### Specific
- `${a}` surround variable names with brackets
  * clarity (and sometimes necessary)
- `command -v '<>' >/dev/null 2>&1 || { echo ''; exit 1; }` to test for whether a command is installed
  * [link to stackoverflow discussion](https://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script)
  * NOTE: May have to reconsider if always using absolute paths
  * NOTE: Not sure how to an absolute path (or if it is even necessary) eg. `command -v /bin/ls`
- Use `/usr/bin/env sh` (instead of `/bin/sh`)
  * Though this is legitimately debatable, 
  * Minor: [Supply arguments in the shebang, cron tabs often have a restricted domain, and arguably an abuse of `env`](https://unix.stackexchange.com/questions/29608/) 
- Place inline comments at least two spaces after the end of the line
  - eg. `printf '%s\n' "$@"  # Mimics ruby's puts syntax`
- TODO: on case statements indentation
- semicolons hug the line of code
  + `{ echo 'a'; }`

# Compact form examples
`if grep -q 'a'; then echo 'a'; else echo 'b'; fi`
`if grep -q 'a'; then echo 'a' & else echo 'b' & fi`
`[ -r 't.txt' ] || { echo 'a'; exit 1; }`
`case "${a}" in a) echo 'a';; *) echo 'default';; esac`
`</dev/null awk 'END{ print("No input awkscript"); }'`

# Functional-programming structuring
- Ternary operator (see clipboard.sh)
- Piping
