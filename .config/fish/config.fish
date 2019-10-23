#if [ -z "$PATH" ]  # Runs test is built-in to fish, runs even if $PATH empty
  set -U fish_user_paths /usr/local/sbin /usr/local/bin /usr/bin /sbin /bin \
    /opt/texlive/2019/bin/x86_64-linux
#end

function exists
  set dirs $PATH  # fish splits $PATH automatically on colons
  for dir in $dirs
    if [ -f "$dir/$argv[1]" ] && [ -x "$dir/$argv[1]" ]
      printf %s "$dir/$argv[1]"
      return 0
    end
  end
  return 1
end

function rrc
  [ (count $argv) = 0 ] && source "$XDG_CONFIG_HOME/fish/config.fish"
  sed 's/"\$(\(.*\))"/(\1)/g' "$HOME/.profile" | source
  source "$XDG_CONFIG_HOME/aliasrc"
  source "$XDG_CONFIG_HOME/envrc"
  #source ~/.profile
end
rrc "Avoid infinite loop"


# At the present, fish cannot store multiline inputs
# See: https://github.com/fish-shell/fish-shell/issues/159
function cd_of
  #set temp ( $argv; set err "$status"; printf x )
  #[ "$err" -ne 0 ] && return "$err"
  set temp ( $argv ) || return "$status"
  if [ "$temp" != "$PWD" ]
    cd "$temp" && ls --color=auto --group-directories-first -hA
  end
end

function fish_prompt
  set exitcode "$status"
  set timer 0
  if [ -n "$last_pid" ] && [ "$last_pid" -gt "0" ]
    set backgroundpid "$last_pid"
  else
    set backgroundpid "0"
  end
  "$XDG_CONFIG_HOME/prompt.sh" "$exitcode" "$timer" "$backgroundpid"
end

# Fish should not add things to clipboard when killing
# See https://github.com/fish-shell/fish-shell/issues/772
set FISH_CLIPBOARD_CMD "cat"
set fish_greeting
