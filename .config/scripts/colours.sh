#!/usr/bin/env sh
# http://chriskempson.com/projects/base16/
# Previews:
# - https://github.com/mbadolato/iTerm2-Color-Schemes
# - http://mswift42.github.io/themecreator/
# - http://ergoemacs.org/emacs/emacs_CSS_colors.html
# Reference implementations 
# - github.com/chriskempson/base16-vim/blob/master/colors/base16-one-light.vim
# - github.com/rakr/vim-one/blob/master/colors/one.vim
# - github.com/balajisivaraman/emacs-one-themes/blob/master/one-themes.el

ID_SET="--- set ~ automatically replaced by 'colours.sh' ---"
ID_END="--- end ~ automatically replaced by 'colours.sh' ---"

#    (light . ((mono1 . "#494B53")
#              (mono2 . "#696C77")
#              (mono3 . "#A0A1A7")
#              (mono4 . "#C2C2C3")
#              (background . "#FAFAFA")
#              (contrast-bg . "#F0F0F0")
#              (low-contrast-bg . "#F5F5F5")
#              (fringe . "#9E9E9E")
#              (accent . "#526FFF")
#              (highlight . "#D0D0D0"))))

#B0="fafafa" # we 0  f default background
#B1="f0f0f1" # gn 1  x lighter background (status bars)
#B2="e5e5e6" # yw 1    selection background
#B3="a0a1a7" # we 1    comments, inivisibles, line highlighting
#B4="696c77" # be 1  d dark foreground (status bars)
#B5="383a42" # bk 0    default foreground, caret, delim, operators
#B6="202227" # ma 1    light foreground (not often used)
#B7="090a0b" # bk 1    light background (not often used)
#B8="ca1243" # rd 0    re: var, xml tags, mkup link text, mkup lists, diff del
#B9="d75f00" # rd 1    or: int, bool, const, xml attributes, mkup link url
#BA="c18401" # yw 0    ye: classes, markup bold, search text bg
#BB="50a14f" # gn 0  h gr: strings, inherited class, markup code, diff ins
#BC="0184bc" # cn 0    cy: support, regexp, escape chars, mkup quotes
#BD="4078f2" # be 0    bl: fn, methods, attribute ids, headings
#BE="a626a4" # ma 0    ma: keyw, storage, selector, mkup italics, diff ch
#BF="986801" # cn 1  s br: deprecated, open/close embedded tags eg. <?php ?>

b0="#fafafa" # we 0  f default background
b1="#487329" # gn 1  x lighter background (status bars)
b2="#c18401" # yw 1    selection background
b3="#9e9e9e" # we 1    comments, inivisibles, line highlighting
b4="#526fff" # be 1  d dark foreground (status bars)
b5="#000000" # bk 0    default foreground, caret, delim, operators
b6="#c2c2c3" # ma 1    light foreground (not often used)
b7="#494b53" # bk 1    light background (not often used)
b8="#ca1243" # rd 0    re: var, xml tags, mkup link text, mkup lists, diff del
b9="#e45649" # rd 1    or: int, bool, const, xml attributes, mkup link url
bA="#986801" # yw 0    ye: classes, markup bold, search text bg
bB="#50a14f" # gn 0  h gr: strings, inherited class, markup code, diff ins
bC="#0184bc" # cn 0    cy: support, regexp, escape chars, mkup quotes
bD="#4078f2" # be 0    bl: fn, methods, attribute ids, headings
bE="#a626a4" # ma 0    ma: keyw, storage, selector, mkup italics, diff ch
bF="#56b6c2" # cn 1  s br: deprecated, open/close embedded tags eg. <?php ?>

#BF="61afef" # cn 1  s br: deprecated, open/close embedded tags eg. <?php ?>
#B6="c678dd" # ma 1    light foreground (not often used)

#*color0:       base05 ! black
#*color1:       base08 ! red
#*color2:       base0B ! green
#*color3:       base0A ! yellow
#*color4:       base0D ! blue
#*color5:       base0E ! magenta
#*color6:       base0C ! cyan
#*color7:       base00 ! white
#*color8:       base07 ! light black
#*color9:       base09 ! light red
#*color10:      base01 ! light green
#*color11:      base02 ! light yellow
#*color12:      base04 ! light blue
#*color13:      base06 ! light magenta
#*color14:      base0F ! light cyan
#*color15:      base03 ! light white

main() {
  run "${HOME}/.Xresources" "!" "$( outln \
    "#define base00 ${b0}" \
    "#define base01 ${b1}" \
    "#define base02 ${b2}" \
    "#define base03 ${b3}" \
    "#define base04 ${b4}" \
    "#define base05 ${b5}" \
    "#define base06 ${b6}" \
    "#define base07 ${b7}" \
    "#define base08 ${b8}" \
    "#define base09 ${b9}" \
    "#define base0A ${bA}" \
    "#define base0B ${bB}" \
    "#define base0C ${bC}" \
    "#define base0D ${bD}" \
    "#define base0E ${bE}" \
    "#define base0F ${bF}" \
  )"

  run "${XDG_CONFIG_HOME:-~/.config}/alacritty/alacritty.yml" "#" "$( outln \
    "  primary:" \
    "    background: '0x${b0#'#'}'" \
    "    foreground: '0x${b5#'#'}'" \
    "" \
    "  cursor:" \
    "    text:       '0x${b0#'#'}'" \
    "    cursor:     '0x${b5#'#'}'" \
    "" \
    "  normal:" \
    "    black:   '0x${b5#'#'}'" \
    "    red:     '0x${b8#'#'}'" \
    "    green:   '0x${bB#'#'}'" \
    "    yellow:  '0x${bA#'#'}'" \
    "    blue:    '0x${bD#'#'}'" \
    "    magenta: '0x${bE#'#'}'" \
    "    cyan:    '0x${bC#'#'}'" \
    "    white:   '0x${b0#'#'}'" \
    "" \
    "  bright:" \
    "    black:   '0x${b7#'#'}'" \
    "    red:     '0x${b9#'#'}'" \
    "    green:   '0x${b1#'#'}'" \
    "    yellow:  '0x${b2#'#'}'" \
    "    blue:    '0x${b4#'#'}'" \
    "    magenta: '0x${b6#'#'}'" \
    "    cyan:    '0x${bF#'#'}'" \
    "    white:   '0x${b3#'#'}'" \
  )"

  # TODO: color16-21
  run "${DOTENVIRONMENT}/.termux/colors.properties" "#" "$( outln \
    "foreground=${b5}" \
    "background=${b0}" \
    "cursor=${b5}" \
    "" \
    "color0=${b5}" \
    "color1=${b8}" \
    "color2=${bB}" \
    "color3=${bA}" \
    "color4=${bD}" \
    "color5=${bE}" \
    "color6=${bC}" \
    "color7=${b0}" \
    "color8=${b7}" \
    "color9=${b9}" \
    "color10=${b1}" \
    "color11=${b2}" \
    "color12=${b4}" \
    "color13=${b6}" \
    "color14=${bF}" \
    "color15=${b3}" \
  )"
}



#  file="$(<<EOF cat
#aslkdjflajdsf
## ${ID_SET}
#qwert
#yuiop
## ${ID_END}
#asdf
#EOF
#  printf a
#)"
#  file="${file%a}"




run() {
  # $1: the filename to edit in place
  # $2: comment character
  # $3: the colors to replace

  # Need to separate reading and writing to $1
  _input="$( cat "$1"; printf a)"; _input="${_input%a}"
  out "${_input}" | {
    eat_till "$2 ${ID_SET}"      || _error='1'
    eat_core "$2 ${ID_END}" "$3" || _error='2'
    eat_rest

    if   [ "${_error}" = '1' ]
      then errln "$1 - opening tag not found"; return 1
    elif [ "${_error}" = '2' ]
      then errln "$1 - closing tag not found"; return 1
    else
      return 0
    fi
  } >"$1"
}


eat_till() {
  # $1: the comment method
  while IFS= read -r _line; do
    outln "${_line}"
    [ "${_line}" != "${_line#"$1"}" ] && return 0
  done
  out "${_line}"
  [ "${_line}" != "${_line#"$1"}" ]
}

eat_core() {
  if  _buffer="$( eat_till "$1"; _e="$?"; printf a; exit "${_e}" )"
      _err="$?"
      _buffer="${_buffer%a}"
      [ "${_err}" = 0 ]
    then outln "$2" "$1"
    else out "${_buffer}"; return 1
  fi
}

eat_rest() {
  while IFS= read -r _line; do
    outln "${_line}"
  done
  out "${_line}"
}

out() { printf %s "$@"; }
outln() { printf %s\\n "$@"; }
errln() { printf %s\\n "$@" >&2; }

main "$@"
