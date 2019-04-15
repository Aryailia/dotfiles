#!/usr/bin/env sh
  # Wrapper for a bunch of utilities for r

# Test suite
# - Trailing empty field <a,b,>
# - Field with newline
# - Quote count even, but evil <a,s"," " "> -> <a|s"| " > * (still malformed)
# - Double quotes must be escaped with two quotes
# - Test case: one double quote <""""> -> <">
# - Single and multiple field
# - Inconsistent number of fields *
# - Unfinished quote should skip to end of verification *
# - Fields can have trailing or leading spaces
#   <  ""  > or <  ye boi  >  -> <ye boi>
# - Fields with newlines or double quotes must be quoted

#%self ~/ime/test.csv add yo " as\"df" erkqwer a &&
#:console %self unittests/test.csv verify && echo 'valid dsv'
#:!console %self unittests/test.csv count && %self unittests/test.csv extract 2 && { %self unittests/test.csv verify && echo 'valid dsv'; }
#:console %self unittests/fail.csv count && %self unittests/fail.csv extract 2 && { %self unittests/fail.csv verify && echo 'valid dsv'; }
#:console %self unittests/test.csv verify && echo 'valid dsv'
#:console delimiter="|" %self ~/.environment/bookmarks.csv verify
main() {
  # Parameters
  delimiter="${DELIMITER:-,}"
  file="$1"
  action="$2"

  if [ "$#" -lt 2 ]; then
    general_help
    exit 1
  else
    shift 2
  fi

  if [ ! -r "${file}" ]; then
    put "${file} does not exist"  1>&2
    exit 1
  fi

  case "${action}" in
    add)
      fieldCount="$(processDSV '(NR == 1){ print NF; exit; }')"

      if [ ! -s "${file}" ] || [ "$#" -ne "${fieldCount}" ]; then
        p "Only $# fields provided."
        p "Please provide ${fieldCount} fields"
        put # newline
        exit 1
      else
        {
          dsv_escape "${1}"; shift 1
          for field in "$@"; do
            p "${delimiter}"
            dsv_escape "${field}"
          done
          put # newline
        } >> "${file}"
      fi
      ;;

    count) processDSV 'END{ print(RecordNumber); }';;
    extract) processDSV 'RecordNumber == '"$1"' { print($0); }' ;;
    print) processDSV '(1) { print FNR ": " $0; }' ;;
    verify)
      # `OriginalField` just an array of $(...) before surround quotes removed
      processDSV '
        function verificationError(str) {
          print("Verification failure") > "/dev/stderr";
          print("====================") > "/dev/stderr";
          printf("%s", str) > "/dev/stderr";

          # END is executed still after exiting
          Result = 1;
          exit 1;
        }

        # Executes with BEGIN before most of `processDSV`
        BEGIN { F = 0; }  # Not necessary, but clearer

        # Executes after `processDSV`
        (!F++) { FieldCount = NF; }  # Only run on first line

        # Check quoting is correct
        (1) {
          for (i = 1; i <= NF; ++i) {

            # Check if surround in quotes if field contains special characters
            if ($(i) ~ /"|\n/ && OriginalField[i] !~ /^".*"$/) {
              verificationError( \
                "Fields with double quotes or newlines must be quoted\n" \
                sprintf("Record %s: %s", NR, $0) "\n" \
                sprintf("Field  %s: %s", i, $(i)) "\n" \
              );
            }

            # Check if double quotes escaped properly
            if ($(i) ~ /^".*"$/) {  # Remove surrounding quotes
              sub(/^"|"$/, "", OriginalField[i]);
            }
            if ((gsub(/"/, "&", OriginalField[i]) % 2) == 1) {  # If odd quote count
              verificationError( \
                "Fields with double quotes or newlines must be quoted\n" \
                sprintf("Record %s: %s", NR, $0) "\n" \
                sprintf("Field  %s: %s", i, $(i)) "\n" \
              );
            }
          }
        }

        # Check field count consistency across all records
        (FieldCount != NF) {
          verificationError( \
            sprintf("Need %s fields. Recieved %s.", FieldCount, NF) "\n" \
            sprintf("Record %s: %s", NR, $0) "\n"  \
          );
        }

        # If quote is never closed, `buildDSVRecord()` execution line repeats
        # `next` without triggering anything else until END is reached
        # END is also executed after an exit outside of END is called
        # 0 exit code is no error, 1 is failure
        END {
          if (Result && Quoting) {
            verificationError( \
              "Double quote not closed.\n" \
              sprintf("Record %s: %s", NextFNR, $0) "\n"  \
            );
          }
          exit Result;
        }
      '
      exit $?
      ;;

    verbose)
      processDSV '
        (1) {
          printf("Record %d:\n", RecordNumber);
          print(OriginalFNR);

          for (i = 1; i <= NF; ++i) {
            printf("  $%d=<%s>\n", i, $i);
          }
          print "====="
        }
      '
      ;;
    help) general_help ;;
    *) general_help
  esac
}

general_help() {
  name="$(basename "$0")"
  put "${name} <filename> <command> [<args>]"
  put "You can change the delimiter by setting environment variable. Eg.:"
  put "  DELIMITER=\"|\" ${name} <filename> verbose"
  put "  DELIMITER=\"\$(echo \"\")\" ${name} <filename> verbose"
  put "Commands"
  put "  add [<fields>]      adds a record, escaping as necessary  "
  put "  count               output the number of records"
  put "  extract [<number>]  appends a record to the file, escaping as needed"
  put "  verify              exit 1 if it is formated improperly"
  put "  help                print this help message"
  put "  print               print the file line by line"
  put "  verbose             print each record and field verbosely"
}

dsv_escape() {
  put "$*" | awk '
    (1){ gsub(/"/, "\"\"", $0); }  # And the escape quotes
    /"|\n/{ $0 = "\"" $0 "\""; }   # Must quote if has any special characters
    (1){ printf("%s", $0); }
  '
}
p() { printf '%s' "$@"; }
put() { printf '%s\n' "$@"; }

# Builds the $... so that they can be interpreted literally
# Awk will then join them back together into $0
#
# See also:
# https://tools.ietf.org/html/rfc4180
# https://stackoverflow.com/questions/45420535/
# https://blog.csdn.net/Meyino/article/details/1509470
#
# Supports
# - leading and trailing spaces for fields
# - arbitrary separator (`-v FS=...` as a param)
# - " and newlines within fields, " must be doubled
# Does not support
# - CRLF (though probably really easy)
# - Backslash newlines and " instead of double " and literal newline
# - MSExcel randomness (special =, and removing leading 0)
processDSV() { awk -v FS="${delimiter}" '
  # Globals:
  # `PrevSeg` is temporary buffer for the parsed current record
  #
  #  For verification:
  # `OriginalField` is an array of `$(...)` that should match what is written in
  #    in the original file with leading and trailing spaces removed
  # `OriginalFNR` is record number corresponding to before parsing
  # `NextFNR`
  # `Quoting` is a boolean for whether following a multiline quote
  #
  # `RecordNumber` is record number after parsing
  # Parameters are the only way to create local variables in awk
  function buildCSVRecord(    _i, _record, _fpat, _continue) {
    StartRecord = NR;

    # If an odd number of quotes, then request next line and append it
    $0 = PrevSeg $0;
    if ((gsub(/"/, "&", $0) % 2) == 1) {  # & has special meaning, so no change
      Quoting = 1;
      PrevSeg = $0 RS;
      _continue = 1;

    # Fields all closed so process
    } else {
      Quoting = 0;
      _record = $0 FS;  # Add FS, so match can deal with trailing blank fields
                        # Eg. <asdf,> can still be read (will skip without)
      $0 = "";
      gsub(/@/, "@A", _record);       # < """foo@bar" >   -> < @B""foo@Abar" >

      # Breakup `_record` into `$(_i)` (writes to `$0` too)
      # Added blank field earlier to preserve trailing empty fields
      #
      # NOTE: Ordinarily awk would set blank lines to have `NF == 0`,
      #       but this will set `$1 = ""` thus `NF == 1`
      do {
        sub(/^ *"/, "@B", _record);   # < ""foo@Abar" > -> < @B"foo@Abar" >
        gsub(/""/, "@C", _record);    # < @B""foo@Abar" > -> < @B@Cfoo@Abar" >
        sub(/@B/, "\"", _record);     # < "@Cfoo@Abar" >  -> < "@Cfoo@Abar" >

        _fpat =           "^ *\"[^\"]*\" *"  # Mimic GNU fpat in two parts
        _fpat = _fpat "|" "^[^" FS "]*"      # Always matches, no chance of none
        if (match(_record, _fpat)) {         # Sets `RSTART` and `RLENGTH`
          $(++_i) = substr(_record, RSTART, RLENGTH); # Split into the `$(_i)`s
        } else {         # Should never take this, but just in case
          $(++_i) = _record;
          _record = "";  # allow loop to terminate
        }

        # Beginning to descape
        # Apply almost the same transforms to both `OriginalField` and `$(_i)`
        gsub(/^ | $/, "", $(_i));     # < "@Cfoo@Abar" > -> <"@Cfoo@Abar">

        # Just for verify method
        # `OriginalField` retains surrounding quotes and escaped quotations
        # Save as close to original (removes whitespace padding)
        OriginalField[_i] = $(_i);
        gsub(/@C/, "\"\"", OriginalField[_i]);
        gsub(/@A/, "@", OriginalField[_i]);

        # `$(_i)` removes surrounding quotes and descapes quotations
        if ($(_i) ~ /^".*"$/) {
          gsub(/^"|"$/, "", $(_i));   # <"@Cfoo@Abar">   -> <@Cfoo@Abar>
        }
        gsub(/@C/, "\"", $(_i));      # <@Cfoo@Abar> -> <"foo@Abar>
        gsub(/@A/, "@", $(_i));       # <"foo@Abar> -> <"foo@bar>

        _record = substr(_record, RSTART + RLENGTH + 1);  # Move past `$(_i)`
        gsub(/@C/, "\"\"", _record);  # Convert back so can be re-parsed
        # Eg. Should parse:      "","" -> @B",@C -> "","" -> "" -> @B" -> ""
        # Without convert back:  "","" -> @B",@C -> "",@C -> @C -> "
      } while (_record != "");

      PrevSeg = "";
      _continue = 0;
    }
    return _continue;
  }
  BEGIN { OFS = FS; OriginalFNR; NextFNR = 1; }
  (Result = buildCSVRecord()) { next; }

  # Use NextFNR because know when to freeze FNR when record finished,
  # but end up with FNR at the end of the record (useful for the next line)
  (1) { OriginalFNR = NextFNR; NextFNR = FNR + 1; }
  (1) { ++RecordNumber; }
'"${1}" "${file}"; }

main "$@"
