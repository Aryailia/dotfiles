if [ -z "$PATH" ]  # Runs test is built-in to fish, runs even if $PATH empty
  #set -U fish_user_paths /usr/local/sbin /usr/local/bin /usr/bin /sbin /bin
  #set -U fish_user_paths /usr/local/bin /usr/bin
end

function rrc
  sed 's/"\$(\(.*\))"/(\1)/g' ~/.profile | source
  #source ~/.profile
  source ~/.config/aliasrc
end
rrc


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
