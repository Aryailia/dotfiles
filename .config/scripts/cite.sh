#/bin/sh

die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }
curl_doi() {
  if [ -n "${1}" ]; then
    printf %s\\n "Curling crossref.org for ${1}"  >&2
    curl -s "https://api.crossref.org/works/${1}/transform/application/x-bibtex"
  else
    printf %s\\n "No doi provided/found" >&2
  fi
}

#else

if true; then
  case "${1}"
    in *youtube.com/*)
      # https://bibtex.com/g/bibtex-format/
      # Also look at how Wikipedia does bibtex citations
      youtube-dl --dump-json --skip-download "${1}" \
        | jq '[.title, .uploader, .upload_date, .webpage_url]' \
        | perl -e 'use JSON; use strict; use warnings;
          my @json = @{decode_json(join("", <STDIN>))};

          # 3-letter month is preferred
          my @month = ("jan", "feb", "mar", "apr", "may", "jun",
            "jul", "aug", "sep", "oct", "nov", "dec");
          my $year = substr($json[2], 0, 4);
          my $month_num = substr($json[2], 4, 2);
          my $month_str = $month[int($month_num) - 1];
          my $day = substr($json[2], 6, 2);

          my $citestem = lc($json[1]);
          $citestem =~ s/[^A-Za-z]//g;

          my $title = $json[0];
          $title =~ s/\{/\\{/g;
          $title =~ s/\}/\\}/g;
          $title =~ s/(^|\s?)"(.*)"/$1\\enquote{$2}/g;

          print "\@online{$citestem$year$month_str,\n";
          print "\tauthor = {},\n";
          print "\ttitle = {$title},\n";
          print "\tpublisher = {$json[1]},\n";
          print "\torganization = YouTube,\n";
          print "\turl = {$json[3]},\n";
          print "\tyear = $year,\n";
          print "\tmonth = $month_str,\n";
          print "\tday = $day,\n";
          print "\turldate = {'"$( date +"%Y-%m-%d" )"'},\n";
          print "}\n";
        '

    # Just the reference
    #;; %*) printf %s\\n "@${1#%}" \
    #  | pandoc --citeproc --bibliography="${BIBLIOGRAPHY}" \
    #    -M "nocite=@*" -f markdown -t plain \
    #  |  sed '1,/^$/d'

    ;; %*) printf %s\\n "@${1#%}" \
      | pandoc --citeproc --bibliography="${BIBLIOGRAPHY}" \
        -f markdown -t plain \
      |  sed '1,/^$/d'

    # The citation
    ;; @*) printf %s\\n "[${1}]" \
      | pandoc --citeproc --bibliography="${BIBLIOGRAPHY}" \
        -M 'suppress-bibliography=true' \
        -f markdown -t plain

    ;; *.pdf)
      [ -r "${1}" ] || die FATAL 1 "Cannot read PDF file '${1}'."

      doi="$( pdfinfo "${1}" | grep -io "doi:.*" \
        || pdftotext "${1}" - 2>&1 >/dev/null | grep -io "doi:" -m 1
      )"
      curl_doi "${doi}"

    ;; doi:*) curl_doi "${1}"

    # run: % test:978-1-292-06118-4
    # 1-292-06118-9
    # 978-1-292-06118-4



    ;; isbn:*)
      curl -s -X POST \
        -H "Content-Type: application/json" \
        -d '{"fromIds":true,"input":"'"${1#isbn:}"'","targetFormat":"Bibtex"}' \
        "https://api.paperpile.com/api/public/convert" \
      | jq -r '.output'


      # How to reverse engineer:
      # 1. Disable extensions so you can debug step
      # 2. Open developer tools on Firefox or Chrome while on the website
      # 3. Navigate to "Debugger" or "Sources" ta
      # 4. Press '{}' in bottom left of the source code view to unminify
      # 5. F8 to step through immediately proceeding JavaScript execution
      # 6. Trigger javascript
      # 7. Add break points as you see fit

      # https://go-to-hellman.blogspot.com/2015/12/xisbn-rip.html
      # https://kitchingroup.cheme.cmu.edu/blog/2015/01/31/Turn-an-ISBN-to-a-bibtex-entry

    #;; oclc:*)
    #  # seems we need an API for this
    #  curl "https://worldcat.org/bib/data/${1#oclc:}"
    #
    ;; arxiv:*)
      # https://gist.github.com/MartinThoma/8133254
      printf %s\\n "todo" >&2

    ;; s|start-webserver)
      port="8000"
      printf %s\\n "Netcat listening on port ${port}" >&2
      while :; do
        printf %s\\n "Reply from port ${port}" \
          | nc -l "${port}" \
          | awk 'BEGIN{print} 1'
      done
    ;; *) printf %s\\n "Please provide a citekey, url, doi, or pdf file" >&2
  esac
fi
