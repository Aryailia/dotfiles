#!/bin/sh

NAME="$( basename "${0}"; printf a )"; NAME="${NAME%?a}"

exit_help() {
  <<EOF cat - >&2
SYNOPSIS
  ${NAME}

DESCRIPTION
  For automating scraping the web for updates. Made with the intent of following
  fics, comics, manga, but any update is possible if you have a web interface.

  The classic use case is curl > pup extraction > jq processing. However,
  theoretically, this supports other methods of finding updates. Using
  twitch-dl, wget, etc. are all possible. At the moment, only curl is supported.

  Websites to follow are defined in the file \$FOLLOW and the definition
  for the pup extraction and jq parsing are defined in \$SCRAPERS.

OPTIONS
  -
    Special argument that says read from STDIN

  --
    Special argument that prevents all following arguments from being
    intepreted as options.

  -1 [<curl> <parser_id> <url>]
    Test the download (curl) and pup part of the process. If no arguments are
    provided, you get the regular menu.

  -2 <parser_id> <filepath>
    Test the call to jq part of the process
EOF
  exit 1
}

# The follow csv file should be 'title	downloader id	scraper id	url'
FOLLOW="${DOTENVIRONMENT}/follow.csv"
# The scrapers should provide 'scraper id	pup syntax	jq syntax'
# `jq` is passed with the -r flag
SCRAPERS="${DOTENVIRONMENT}/scrapers.csv"

# if (True): just for the text alignment
main() {
  ACTION='PUP_JQ'
  ARG=''

  # Options processing
  args=''; literal='false'
  for a in "$@"; do
    "${literal}" || case "${a}"
      in --)         literal='true'; continue
      ;; -h|--help)  exit_help

      ;; -1)  ACTION='PUP'
      ;; -2)  ACTION='JQ'

      ;; -*) die FATAL 1 "Invalid option '${a}'. See \`${NAME} -h\` for help"
      ;; *)  args="${args} $( outln "${a}" | eval_escape )"
    esac
    "${literal}" && args="${args} $( outln "${a}" | eval_escape )"
  done

  eval "set -- ${args}"

  #run: sh % -1
  case "${ACTION}"
    ############################################################################
    # For testing the first step
    in PUP)
      printf %s\\n 'For testing the first pass with `pup`' >&2

      if [ $# = 0 ]; then
        # Select with follow site to test with fzf
        site_to_test="$( python3 -c 'if (True):'"${funcs}"'
          to_follow = read_follow(sys.argv[1])
          scrapers = read_scrapers(sys.argv[2])
          for (title, downloader, parser, link) in to_follow:
            print(f"%s\t|%s\t|%s\t|%s" % (title, downloader, parser, link))

        ' "${FOLLOW}" "${SCRAPERS}" \
          | column -ts '	' \
          | fzf
        )" || exit "$?"
      elif [ $# = 3 ]; then
        site_to_test="$( printf '%s\t|%s\t|%s\t|%s' '' "$@"  )"
      else
        die FATAL 1 "Need three arguments: <downloader_id> <parser_id> <url>"
      fi

      # Run poll_updates for that one site and just do the PUP branch
      python3 -c 'if (True):'"${funcs}"'
          cols = [x.strip() for x in sys.argv[1].split("|")]
          scrapers = read_scrapers(sys.argv[2])
          print(asyncio.run(poll_updates(PUP, scrapers, *cols)))
      ' "${site_to_test}" "${SCRAPERS}"



    ############################################################################
    # For testing the second step
    ;; JQ)
      if [ $# = 2 ]; then
        site_to_test="$( printf '%s\t%s\t%s\t%s' '' '' "${1}" "${2}"  )"
        python3 -c 'if (True):'"${funcs}"'
          cols = [x.strip() for x in sys.argv[1].split("\t")]
          scrapers = read_scrapers(sys.argv[2])
          print(asyncio.run(poll_updates(JQ, scrapers, *cols)))
        ' "${site_to_test}" "${SCRAPERS}"
      else
        die FATAL 1 "Please pass '<parser_id> <filename>' as arguments"
      fi



    ############################################################################
    # The regular poll all follow sites for updates
    ;; PUP_JQ)
      output="$( python3 -c 'if (True):'"${funcs}"'
          async def main():
            to_follow = read_follow(sys.argv[1])
            scrapers = read_scrapers(sys.argv[2])

            # Debugging
            #for s in to_follow: print(s)
            #for (key, value) in scrapers.items(): print(value)


            #print("Starting docker \"share\" container...", file=sys.stderr)
            #await run(None, ["docker", "start", "share"])

            print("Polling updates...", file=sys.stderr)
            results = await asyncio.gather(*[
              poll_updates(PUP_JQ, scrapers, *item) for item in to_follow
            ])
            print("\n".join(results))

            #print("Stopping docker \"share\" container...", file=sys.stderr)
            #await run(None, ["docker", "stop", "share"])

          asyncio.run(main())
      ' "${FOLLOW}" "${SCRAPERS}" \
        | column -ts '	'
      )"

      while :; do
        select="$( printf %s\\n "${output}" | fzf )" || exit "$?"
        extract_link "${select}" | clipboard.sh -w
        printf %s\\n "Copied selection to clipboard" "" >&2
        printf %s\\n "${output}"
      done

    ;; *)  die DEV 1 'Typo for ${ACTION}'
  esac
}

# Takes 'title	curl	source	https://link.to.site/'
# and extracts the URL
extract_link() {
  case "${1}"
    in *https://*)  printf %s "https://${1#*https://}"
    ;; *http://*)   printf %s "http://${1#*http://}"
    ;; *)  printf %s\\n "FATAL 1: ${1} does not contain a link" >&2; exit 1
  esac
}

funcs='
          import asyncio
          import subprocess
          import sys

          PUP    = 1
          JQ     = 2
          PUP_JQ = 3

          def read_follow(csv):
            to_follow = []
            with open(csv) as file:
              for line in file.read().splitlines():
                cols = [x.strip() for x in line.split("\t")]
                if len(cols) == 4 and not cols[0].startswith("#"): to_follow.append(cols)
            return to_follow

          def read_scrapers(csv):
            scrapers = {}
            with open(csv) as file:
              for line in file.read().splitlines():
                cols = [x.strip() for x in line.split("\t")]
                if len(cols) == 3 and not cols[0].startswith("#"):
                  scrapers[cols[0]] = cols[1:]
            return scrapers

          # Execute external command async
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
              exit(proc.returncode)
            return stdout.decode();

          async def download():
            pass

          # {key} is the key for scrapers
          async def poll_updates(action, scrapers, title, command, key, url):
            result = ""
            if action == JQ:
              pass
            elif command == "curl":
              result = await run(None, ["curl", "-Ls", url])
              result = await run(result, ["pup", scrapers[key][0]])
            elif command == "docker":
              print("We do not support docker yet", file=sys.stderr)
              #result = await run(None, ["docker", "exec", "share", "/share/scrape/scrape.py", url])
              exit(1)
            else:
              print(f"We do not support %s yet" % command, file=sys.stderr)
              exit(1)

            if action == PUP:
              return result
            elif action == JQ:
              # Do not curl, and use <url> as filepath
              print(["jq", "--raw-output", scrapers[key][1], url], file=sys.stderr)
              return await run(None, ["jq", "--raw-output", scrapers[key][1], url])
            else:
              result = await run(result, ["jq", "--raw-output", scrapers[key][1]])
              return f"%s\t%s\t%s" % (title, result.strip(), url)
'

outln() { printf %s\\n "$@"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }


main "$@"
