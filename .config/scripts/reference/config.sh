#!/usr/bin/env sh
  # for the indent setting

# Helper
################################################################################
# Settings
################################################################################
             font="monospace"
        font_size="9"
            alpha="c8"  # 200

       foreground="2a2b32"
foreground_bright="a8a19f"
       background="ffffff"

            black="000000"
     black_bright="2a2b32"
              red="da3e39"
       red_bright="da3e39"
            green="41933e"
     green_bright="41933e"
           yellow="855504"
    yellow_bright="855504"
             blue="315eee"
      blue_bright="315eee"
          magenta="930092"
   magenta_bright="930092"
     #0e6fad 34c284
             cyan="0db6d8"
      cyan_bright="0db6d8"
            white="fffefe"
     white_bright="fffefe"



################################################################################
# Main
################################################################################

# isPermanent ? file : /dev/null 
output() {
  if "$1"
    then printf '%s' "$2"
    else printf '%s' '/dev/null'
  fi
}

# To run at the end, so run logic is together with settings
main() {
  # Combined version of the list above
  hex_colors="$(p \
    "$black" "$red" "$green" "$yellow" \
    "$blue" "$magenta" "$cyan" "$white" \
    "$black_bright" "$red_bright" "$green_bright" "$yellow_bright" \
    "$blue_bright" "$magenta_bright" "$cyan_bright" "$white_bright" \
    "$foreground" "$foreground_bright" "$background" "$alpha" \
  | sed 's/^/#/')"
  rgb_colors="$(p "$hex_colors" | hex2dec)"
  alpha_decimal="$(p "$alpha" | hex2dec)"
  alpha_percentage="$(math "$(floor "$alpha_decimal / 256 * 100 + 0.5")")"
  
  # Change $write to use $temporary if want to disable (useful for testing)
  permanent="true"
  temporary="false"
  write="output $permanent "

  # Format explanation - Double escaping needed (but can get away with less)
  # 1) First layer is because double quotes use backslash to escape 
  # 2) $format is used in (ie. printf "$format" ...) use backslash to escape
  # Thus \\\\ -> \\ -> \, which then is used by sed

  ##############################################################################
  # Applying
  ##############################################################################

  # For all of .Xresources
  X_path="$HOME/NEW/.Xresources"
  X_format="s/\\\\($(build_padded_sed '!\{0,1\}' '%s' ':')\\\\).*/\\\\1%s/"
  X_inp="$(build_padded_sed '!\{0,1\}' '%s' ':')"
  X_out="\\\\1%s"
  p "$X_inp"
  p "$X_out"

  # Xresources, the defaults
  X_hash="$(standard_labels '*' 'color' \
    | hash_from_zip "$hex_colors" \
    | hash_merge "*background=#$background" "*foreground=#$foreground" \
      "*foreground_bold=#$foreground_bright" "*cursor=#$cursor" \
  )"
  <"$X_path" config "$X_inp" "$X_out" "$X_hash" "$($write "$X_path")"
  #<"$X_path" config "$X_format" "$X_hash" "$($write "$X_path")"
  #cat $X_path
  return
  
  # Simple Terminal (with Xresources patch) in Xresources
  st_hash="$(standard_labels 'st.' 'color' \
    | hash_from_zip "$hex_colors" \
    | hash_merge "st.opacity=$alpha_decimal" \
  )"
  <"$X_path" config "$X_format" "$st_hash" "$($write "$X_path")"

  # URXVT in Xresources
  URxvt_hash="URxvt.background=[$alpha_percentage]#$background"
  <"$X_path" config "$X_format" "$URxvt_hash" "$($write "$X_path")"
  
  # Lilyterm
  lily_path="$HOME/NEW/lilyterm.conf"
  lily_format="s/\\\\($(build_padded_sed '%s' ':' )\\\\).*/\\\\1%s/"
  lily_hash="$(standard_labels '' 'Color' \
    | hash_from_zip "$hex_colors" \
    | hash_merge "foreground_color=$foreground" \
      "background_color=$background" "transparent_background=$alpha_decimal" \
  )"
  <"$lily_path" config "$lily_format" "$lily_hash" "$($write "$lily_path")"
}


################################################################################
# Helper functions - to be used by the useable functions
################################################################################
p() { printf '%s\n' "$@"; }
math() { awk "BEGIN{ print $* }"; }
floor() { printf 'sprintf("%%d", %s)' "$*"; }
 

# Escape if special symbol in sed regexp. Want the literal ASCII characters
_sed_escape() {
  #printf '%s\n' "$1" | sed 's/\([.\\\/]\)/\\\1/g'
  </dev/stdin sed 's/\([.*\\\/]\)/\\\1/g'
}

# Extracts the nth row (oneth-indexed)
_array_get() {
  # I vaguely recall portable sed needing trailing newline to include last line
  # Quits when $1 row reached, then delete everything but last
  </dev/stdin sed "${1}q;d"
}

# Take the "$key=$value" format, separated by lines
_get_key() {
  </dev/stdin awk 'BEGIN{FS="="}{print $1}'
}
_get_value() {
  </dev/stdin awk 'BEGIN{FS="="}{print $2}'
}
_hash_get() {
  #hash<-stdin
  key="$(p "$1" | _sed_escape)"
  </dev/stdin grep "^$key=" | _get_value
}

################################################################################
# Useable
################################################################################

# Convert hex number (in tokens of two digits) to csv decimal
hex2dec() {
  </dev/stdin awk '{
    result=sprintf("%d", "0x"substr($0,1,2))
    for (i = 3; i < length($0); i += 2) {
      result=result","sprintf("%d", "0x"substr($0,i,2))
    }
  }{ print result }'
}

# Generate all the labels with $1 as prefix
# and on newlines (usuable with _array_get())
# eg. `standard_labels '*' 'color'`
standard_labels() {
  printf "${1}${2}%s\n" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
}

# Zips stdin (newline separated list of keys) with $value_list into a hash
# Hash is newline separated list of entries formated: "$key=$value"
hash_from_zip() {
  #hash<-stdin
  value_list="$1"
  index=0
  while IFS= read -r key; do
    index=$((index + 1))
    printf '%s=%s\n' "$key" "$(p "$value_list" | _array_get "$index")"
  done
}

# Merges entries into $basehash (stdin)
# Each parameter should be a single entry to be merged
hash_merge() {
  # basehash<-stdin
  merge="$(p "$@")"

  # Go through the bash hash and merge any values found in {merge}
  ignore=""  # Also build the regexp of keys already included
  while IFS= read -r keyvalue; do
    key="$(p "$keyvalue" | _get_key)"
    escaped_key="$(printf '%s\n' "$key" | _sed_escape)"
    override="$(printf '%s\n' "$merge" | grep "^$escaped_key=")"
    
    # If something to merge is not found
    if test -z "$override"; then  # leave unchanged
      printf '%s\n' "$keyvalue"
    else  # change value to the mergeable provided
      printf '%s=%s\n' "$key" "$(p "$override" | _get_value)"
    fi
    ignore="$ignore^$key=\\|"
  done

  # Print the ones not already found with grep
  ignore="$(printf '%s' "$ignore" | head --byte -2)"
  printf '%s' "$merge" | grep --invert-match "$ignore"
}

# Adds whitespace regexp between each parameter and around entire regexp
# then escapes backslashes
# End goal is for use in `sed "$(printf)`
# eg. `build_padded_sed '#\{0,1\}' '%s'` -> "\\s*\\#\\{0,1\\}\\s*%s\\s*"
build_padded_sed() {
  # Print nothing if completely blank
  if test -n "$*"; then
    # Format: whitespace param whitespace ... param whitespace
    # printf uses backslash to escape so it prints '\s*'
    # then backslash escapes the parameter and the whitespace regexp
    (printf '\\s*'; printf '%s\\s*' "$@") | sed 's/\\/\\\\/g' # and escape
  fi
}

# TODO: Deal with hash keys/values having equal sign?
# TODO: Learn how to use `tee` to avoid using `cat -`
_hash_has_key() {
  #hash="$(</dev/stdin cat -)"
  format="$1"
  query="$2"
  #p "$hash" | sed 's/=.*$//' | _sed_escape | (
  while IFS= read -r key; do
    p "$query" | grep --quiet "$(printf "$format" "$key")" && exit 0
    #p "$query" | grep --quiet "$toMatch" && (
    #  p "$hash" | grep "$toMatch"
    #  exit 0
    #)
  done
  exit 1
}

# {format} is a printf format
# TODO: Add line to $file if provided option in $hash not present in $file
config() {
  #file="$(</dev/stdin cat -)"
  inp_format="$1" # The printf %s that each setting line should follow
  out_format="$2" # The printf %s that each setting line should follow
  hash="$3" # The settings hash
  output="$4" # Where to output the changes

  keys="$(p "$hash" | sed 's/=.*$//')"
  #p $hash | hash_has_key "$inp_format" "*background:asdkfj" && p 'oyyoyoyoy'
  #p "$(printf 's/\(%s\).*/\\1/' "$inp_format")"
  
  # As piping spawns a subshell, outer $result is out of scope of while loop
  while IFS= read -r input; do
    p "$keys" | _hash_has_key "$inp_format" "$input"
#    if false; then # p "$hash" | _hash_has_key "$inp_format" "$input"; then
#      #p "$input" | sed "$(printf "s/\\\\(//")"
#      #key="$(p "$keyvalue" | _get_key | _sed_escape)"
#      #value="$(p "$keyvalue" | _get_value | _sed_escape)"
#      #p "$(printf "s/\\\\($inp_format\\\\)/$out_format/" "color" "12")"
#      printf ''
#    else
#      #p "$input"
#      printf ''
#    fi
  done
}

config2() {
  file="$(</dev/stdin cat -)"
  format="$1" # The printf %s that each setting line should follow
  hash="$2" # The settings hash
  output="$3" # Where to output the changes
  
  # As piping spawns a subshell, outer $result is out of scope of while loop
  p "$hash" | (
    temp="$file"  # Explicitly signals $result is local
    while IFS= read -r keyvalue; do 
      key="$(p "$keyvalue" | _get_key | _sed_escape)"
      value="$(p "$keyvalue" | _get_value | _sed_escape)"
      temp="$(p "$temp" | sed "$(printf "$format" "$key" "$value")")"
    done
    p "$temp" 
  ) >"$output"  # Explicitly output to stdout
}

# Execute
main
