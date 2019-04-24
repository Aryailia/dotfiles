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

scheme=""
scheme="${scheme}("
scheme="${scheme}https?|s?ftp|udp|mailto|magnet|file|irc|data"
scheme="${scheme}|gopher|mid|cid|news|nntp|prospero|telnet|wais"
scheme="${scheme})"

userinfo="([A-Za-z0-0_.:]+@)"  # TODO: password (deprecated)
port="[0-9]{1,5}"
host_character='[-a-zA-Z0-9%_]'
path_character='[-a-zA-Z0-9%_:=+.~#=@?&/!;,]'
regexp=""
regexp="${regexp}(${scheme}://${userinfo}?)?"
regexp="${regexp}${host_character}+(\.${host_character}+)+"
regexp="${regexp}(:${port})?"
regexp="${regexp}""(/${path_character}*)?"


puts() { printf %s\\n "$@"; }
prints() { printf %s "$@"; }
check() { prints "|$1| - "; puts "|$(puts "$1|" | commands -o)|";  }

commands() {
  case "$1" in
    -t|--test)
      check 'https://user@asdf.com/qwer?q=v#3k4j'
      check 'https://user@asdf@asdf.com/'
      ;;
    --bookmarks)
      bash -c 'diff \
        <(<"${DOTENVIRONMENT}/bookmarks.csv" scan.sh -o)  \
        <(<"${DOTENVIRONMENT}/bookmarks.csv" cut -d "|" -f 4 \
          #| sed "s/^ *//;s/ *\$//"
        )'
      ;;
    -o)  <&0 grep -io -E "${regexp}" | uniq ;;

    -m|--menu)
      #<&0 commands | fzf | commands -o
      <&0 commands -o | fzf
      ;;

    *)   <&0 grep -i -E "${regexp}" | uniq ;;
  esac
}

<&0 commands "$@"
