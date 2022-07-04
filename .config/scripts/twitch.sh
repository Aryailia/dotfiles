#!/bin/sh
# As of Twitch API v5 (helix), you need to oauth login your client
# This is achievable via curl, but I do not want to login to twitch
#
# This instead uses `twitch-dl` to query videos (i.e. web scraping) to query
# what videos a given twitch stream has released. It then uses `streamlink`
# to handle passing the appropriate arguments to `mpv`

# So either:
# 1. package manger install twitch-dl (likely no distribution offers this)
# 2. `pip3 install twitch-dl` (consider `--user` or installing globally)

NAME="$( basename "${0}"; printf a )"; NAME="${NAME%?a}"

show_help() {
  printf %s\\n "SYNOPSIS" " ${NAME} <COMMAND> [OPTIONS]" >&2

  printf %s\\n "" "COMMANDS" >&2
  awk '
    /^my_do/    { run = 1; next; }
    /^\}$/      { run = 0; }
    run && /^    in|^    ;;/ {
      sub(/^ *in |^ *;; /, "", $0);
      sub(/).*/, "", $0);
      if ($0 != "" && $0 != "*" && $0 != "-*") print "  " $0;
    }
  ' "${0}"


  printf %s\\n "" "OPTIONS" >&2
  awk '
    /"\$\{literal\}" \|\| case "\$\{1\}"$/ { run = 1; next; }
    /esac$/                                { exit; }
    run {
      sub(/^ *in |^ *;; /, "", $0);
      sub(/).*/, "", $0);
      if ($0 != "" && $0 != "*" && $0 != "-*") print "  " $0;
    }
  ' "${0}"
}

BLUE='\001\033[34m\002'
RED='\001\033[31m\002'
GREEN='\001\033[32m\002'
YELLOW='\001\033[33m\002'
BLUE='\001\033[34m\002'
MAGENTA='\001\033[35m\002'
CYAN='\001\033[36m\002'
CLEAR='\001\033[0m\002'

#run: time sh % f
LIVE_DEFAULT="480p,480p30,360p,360p30,worst"
VOD_DEFAULT="360p,360p30,audio_only,worst,1080p30,1080p60"


main() {
  START_TIME=""

  # Options processing
  args=''
  literal='false'
  while [ "$#" -gt 0 ]; do
    "${literal}" || case "${1}"
      in --)         literal='true'; shift 1; continue
      ;; -h|--help)  show_help

      ;; -s|--start-time)  START="${2:+"--hls-start-offset ${2}"}"; shift 1
      ;; -q|--quality)     QUALITY="${2}"; shift 1

      ;; -*)  die FATAL 1 "Invalid option '${1}'. See \`${NAME} -h\` for help"
      ;; *)   args="${args} $( outln "${1}" | eval_escape )"
    esac
    "${literal}" && args="${args} $( outln "${1}" | eval_escape )"
    shift 1
  done

  [ -z "${args}" ] && { show_help; exit 1; }
  eval "set -- ${args}"

  [ "$#" = 0 ] && eval "set -- $( prompt '.*' "$( outln \
    "${CYAN}follow${CLEAR}" \
    "${CYAN}go${CLEAR} <channel>" \
    "${CYAN}videos${CLEAR} <channel>" \
    "Enter one of the options: ${CYAN}" \
  )" )"
  my_do "$@"
}

my_do() {
  case "${1}"
    in g*|go)
      case "${2}"
        # https://github.com/streamlink/streamlink/issues/134
        in http*)  streamlink --player-passthrough hls \
          "${2}" "${QUALITY:-"${VOD_DEFAULT}"}" $START
        ;; *)      streamlink --player-passthrough hls \
          "https://twitch.tv/${2}" "${QUALITY:-"${LIVE_DEFAULT}"}" $start
      esac

    ;; v*|videos)
      input="$( twitch-dl videos "${2}" | perl -e "${remove_tty_codes}" )" \
        || exit "$?"
      input="$(
        printf %s\\n "https://twitch.tv/${2}|                    View ${2} LIVE"
        printf %s\\n "${input}" | perl -e "${show_videos}" "${2}"
      )" || exit "$?"
      select_input --prompt="${2}'s videos> " --with-nth="2.."

      if [ "${one}" != "${one#*/videos/}" ]
        then my_do go "${one}"
        else my_do go "${one}"
      fi

    ;; f*|follow)
      # Using python3 because twitch-dl is python, so acceptable cost
      # Run these `twitch-dl` network requests async
      input="$( python3 -c 'if (True):
        import asyncio
        import subprocess
        import sys

        async def run(stdin, cmd):
          proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdin  = (None if stdin is None else asyncio.subprocess.PIPE),
            stdout = asyncio.subprocess.PIPE,
            stderr = asyncio.subprocess.PIPE,
          )

          stdout, stderr = await proc.communicate((None if stdin is None else stdin.encode()))
          if stderr:
            print(f"[stderr]\n{stderr.decode()}", file=sys.stderr)
          if proc.returncode != 0:
            if stdout:
              print(f"[stdout]\n{stdout.decode()}\n", file=sys.stderr)
            #exit(proc.returncode)
          return stdout.decode();

        async def list_videos(length, name):
          vid = await run(None, ["twitch-dl", "videos", name])
          raw = await run(vid, ["perl", "-e", sys.argv[2]])
          out = await run(raw, ["perl", "-e", sys.argv[3], name])
          # "name | <only|first|video|info...>"
          return f"%-{length}s|%s" % (name, out.partition("\n")[0])


        async def main():
          with open(sys.argv[1]) as file:
            stream_names = file.read().splitlines()
          max_length = 0
          for s in stream_names:
            max_length = len(s) if len(s) > max_length else max_length

          results = await asyncio.gather(*[
            list_videos(max_length, name) for name in stream_names
          ])
          print("\n".join(results))

        asyncio.run(main())
      ' "${DOTENVIRONMENT}/streams.csv" "${remove_tty_codes}" "${show_videos}"
      )" || exit "$?"
      #printf %s\\n "${input}"
      #<raw2 perl -e "${show_videos}"
      select_input --with-nth="1,3.."
      my_do videos "${one%% *}" # Trim ${name}

    ;; t*|test) twitch-dl videos "${2}" | remove_tty_codes | show_videos
  esac
}

# Cannot pipe into this as we are passing data via variable namespace
# $input:      input
# $one..$five: output
select_input() {
  _select="$( printf %s\\n "${input}" \
    | fzf --reverse --delimiter='\|' "$@"
  )" || exit "$?"
  IFS='|' read -r one two three four five <<EOF
${_select}
EOF
}


#perl
remove_tty_codes='
  while (<STDIN>) {
      # Remove terminal escape codes
      # https://unix.stackexchange.com/questions/14684/
      s/ \e[ #%()*+\-.\/]. |
         \e\[ [ -?]* [@-~] |          # CSI ... Cmd
         \e\] .*? (?:\e\\|[\a\x9c]) | # OSC ... (ST|BEL)
         \e[P^_] .*? (?:\e\\|\x9c) |  # (DCS|PM|APC) ... ST
         \e. //xg;
      print $_;
  }
'

#perl, accepts stream title as $ARGV[0] for STDERR messages
show_videos='
  use v5.14;
  use strict;
  use warnings;
  use Time::Piece;
  use Encode;

  # Iterating line by line of STDIN
  my $i = -1;
  my @list;
  {
    my $previous_line = "\n";
    while (<STDIN>) {
      if (0) {
        # Skip inital stuff Loading videos rubbish
      } elsif ($previous_line eq "\n" && $_ =~ /^Video \d+$/) {
        $list[++$i] = $_;
      } elsif ($i >= 0) {
        $list[$i] .= $_;
      }
      $previous_line = $_;
    }
  }

  sub time_ago {
    if ($_[0] < 60) {          # within a minute
      return "$_[0] sec";
    } elsif ($_[0] < 3600) {   # within an hour
      return int($_[0] / 3600) . " min";
    } elsif ($_[0] < 86400) {  # within a day
      return int($_[0] / 3600) . " hr " . int(($_[0] % 3600) / 60) . " min";
    } elsif ($_[0] < 432000) { # 5 days
      return int($_[0] / 86400) . " days " . int(($_[0] % 3600) / 3600) . " hr";
    } else {
      return int($_[0] / 86400) . " days";
    }

  }

  my $last = "";
  my @max_lengths = (0,0,0,0);
  for my $i (0..$#list) {
    if ($list[$i] =~ /
        Video\ (\d+)\n       # $1: id
        ((?:.*\n)+?)         # $2: title
        (?:.+ playing .+\n)? # $3-5: date, time, length
        Published\s ([0-9-]+) \s@\s ([0-9:]+) \s+Length:\s+ (
          (?:(\d+)\sh)?\s*   # $6: hours
          (?:(\d+)\smin)?\s* # $7: minutes
          (?:(\d+)\ssec)?\s* # $8: seconds
        )\n
        (http.+)             # $9: url
      /x
    ) {

      my $id = $9;
      my $title = $2;
      my $time = "$3 $4";
      my $h = defined($6) ? int($6) : 0;
      my $m = defined($7) ? int($7) : 0;
      my $s = defined($8) ? int($8) : 0;

      $title =~ s/\n$//g;
      my $diff = localtime()
        - int($h) * 3600 - $m * 60 - $s
        - Time::Piece->strptime($time, "%Y-%m-%d %H:%M:%S");
        #- Time::Piece::localtime->strptime($time, "%Y-%m-%d %H:%M:%S");
      my $ago = time_ago($diff) . " ago";

      $list[$i] = [$id, sprintf("%d:%02d:%02d", $h, $m, $s), $ago, $title];
      $#max_lengths == $#{$list[$i]} or die "DEV: update lengths";
      for my $j (0..$#max_lengths) {
        my $len = length(Encode::encode("UTF-8", $list[$i][$j]));
        #my $len = length($list[$i][$j]);
        $max_lengths[$j] = $len > $max_lengths[$j] ? $len : $max_lengths[$j];
      }
      #printf("%s|%s|%02d:%02d:%02d|%s\n", $1, $2, $h, $m, $s, $ago);
    } else {
      say STDERR "Could not process VOD for \"$ARGV[0]\":\n$list[$i]";
      exit 1;
    }
  }

  @max_lengths = map { "%-${_}s" } @max_lengths;
  $max_lengths[1] =~ s/-//;
  $max_lengths[2] =~ s/-//;
  my $fmt = join "|", @max_lengths;

  for my $entry (@list) {
    printf("$fmt\n", @$entry);
  }
'

# Helpers
outln() { printf %s\\n "$@"; }
pc() { printf %b "$@" >/dev/tty; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

prompt() {
  pc "${2}"; read -r value; pc "${CLEAR}"
  while outln "${value}" | grep -qve "${1}"; do
    pc "${3:-"${2}"}"; read -r value
    pc "${CLEAR}"
  done
  printf %s "${value}"
}

<&1 main "$@"
