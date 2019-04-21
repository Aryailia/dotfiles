#!/usr/bin/env sh
# Pretty sure grep -E is not portable

# Very detailed: https://stackoverflow.com/questions/161738/

#[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)
#grep -Eoi '<a [^>]+>' | 
#grep -Eo 'href="[^\"]+"' | 
#grep -Eo '(http|https)://[^/"]+'
#user@domain:port

#user=''
#domain=''
protocols="https?|s?ftp|udp|mail|magnet|file"
domain_character='[-a-zA-Z0-9:%_+.~]'
  path_character='[-a-zA-Z0-9:%_+.~#=@?&/!,]'
regexp=""
regexp="${regexp}""((${protocols}))"'://([A-Za-z0-0_.]+@)?)?'
regexp="${regexp}""${domain_character}+"
regexp="${regexp}""(/(${path_character}+)?)?"


puts() { printf %s\\n "$@"; }
prints() { printf %s "$@"; }
check() { prints "$1 - "; puts "$1" | "${commands}" -o;  }

commands() {
  case "$1" in
    -t|--test)
      check 'https://user@asdf.com/'
      check 'https://user@asdf@asdf.com/'
      diff a b
      ;;
    --bookmarks)
      bash -c 'diff \
        <(<bookmarks.csv scan.sh -o)  \
        <(<bookmarks.csv cut -d\| -f 4 | sed "s/^ *//;s/ *$//")' ;;
    -o)  <&0 grep -io -E "${regexp}" | uniq ;;

    -m|--menu)
      #<&0 commands | fzf | commands -o
      <&0 commands -o | fzf
      ;;
    *)   <&0 grep -i -E "${regexp}" | uniq ;;
  esac
}

<&0 commands "$@"
