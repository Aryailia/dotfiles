#!/usr/bin/awk -f
  #:!console /tmp/preview.sh
# TODO: If no changes then print no changes, otherwise print changed

BEGIN{
  hConfig["font"]              = "monospace"
  hConfig["font_size"]         = "9"
  hConfig["alpha"]             = "c8" # 200

  hConfig["foreground"]        = "2a2b32"
  hConfig["foreground_bright"] = "a8a19f"
  hConfig["background"]        = "ffffff"

  hConfig["0"]                 = "000000" # black
  hConfig["8"]                 = "2a2b32" # black_bright
  hConfig["1"]                 = "da3e39" # red
  hConfig["9"]                 = "da3e39" # red_bright
  hConfig["2"]                 = "41933e" # green
  hConfig["10"]                = "41933e" # green_bright
  hConfig["3"]                 = "855504" # yellow
  hConfig["11"]                = "855504" # yellow_bright
  hConfig["4"]                 = "315eee" # blue
  hConfig["12"]                = "315eee" # blue_bright
  hConfig["5"]                 = "930092" # magenta
  hConfig["13"]                = "930092" # magenta_bright
  hConfig["6"]                 = "0db6d8" # cyan #0e6fad 34c284
  hConfig["14"]                = "0db6d8" # cyan_bright
  hConfig["7"]                 = "fffefe" # white
  hConfig["15"]                = "fffefe" # white_bright

  sConfigDir = ENVIRON["HOME"]"/NEW"

  sAlphaDecimal = hexpair2decimalCSV("c8")
  sAlphaPercentage = round(sAlphaDecimal / 2.55)

  # Xresources
  delete hX;
  mutateCopyColors(hConfig, hX, "*color%s", "#%s");
  hX["*cursor"]          = "#"hConfig["cursor"];
  hX["*foreground"]      = "#"hConfig["foreground"];
  hX["*foreground_bold"] = "#"hConfig["foreground_bright"];
  hX["*background"]      = "#"hConfig["background"];

  hX["URxvt.background"] = "["sAlphaPercentage"]#"hConfig["background"];

  mutateCopyColors(hConfig, hX, "st.color%s", "#%s");
  hX["st.opacity"]       = sAlphaDecimal;
  hX["st.foreground"]    = "#"hConfig["foreground"];
  hX["st.background"]    = "#"hConfig["background"];
  process(sConfigDir"/.Xresources", hX, "^\s*!", pad(":"), "%s");


  # LilyTerm
  delete hLily;
  mutateCopyColors(hConfig, hLily, "Color%s", "#%s");
  hLily["foreground_color"] = "#"hConfig["foreground"];
  hLily["background_color"] = "#"hConfig["background"];
  hLily["cursor_color"]     = "#"hConfig["cursor"];
  process(sConfigDir"/lilyterm.conf", hLily, "^\s*#", pad("="), "%s");
}

function round(sInput) {
  return sprintf("%d", sInput + 0.5);
}

function hexpair2decimalCSV(sInput) {
  result = sprintf("%d", "0x"substr(sInput, 1, 2));
  for (i = 3; i < length(sInput); i += 2) {
    result = result","sprintf("%d", "0x"substr(sInput, i, 2));
  }
  return result;
}

function mutateCopyColors(hConfig, hTarget, pInput, pOutput) {
  for (i = 0; i < 16; ++i) {
    hTarget[sprintf(pInput, i)] = sprintf(pOutput, hConfig[i]);
  }
}

function pad(pDelimiter) {
  return sprintf("^[ \\t]*%%s[ \\t]*%s[ \\t]*", pDelimiter);
}

function escape(sUnescaped) {
  gsub(/[\\\^\$\.\[\|\]\(\)\|\*\+\?]/, "\\\\&", sUnescaped);
  return sUnescaped;
}

function process(sFilename, hConfig, pComment, pInput, pOutput) {
  result = ""
  while ((getline line < sFilename) > 0) {
    # Just add line if comment or whitespace/empty
    if (match(line, pComment) || match(line, /^[ \t]*$/)) {
      result = result"\n"line

    } else {
      found = 0;

      # Check if any of {hConfig} applies to current {line}
      for (sKey in hConfig) {
        if (match(line, sprintf(pInput, escape(sKey)))) {
          result = result"\n"substr(line, RSTART, RLENGTH) \
            sprintf(pOutput, hConfig[sKey]);
          found = 1;
          break;
        }
      }
      # Otherwise just add line
      if (found == 0) result = result"\n"line;
    }
  }

  print result >sFilename;
  return result;
}


function printArray(vOriginal) {
  for (sIndex in vOriginal) {
    print sIndex ": " vOriginal[sIndex];
  }
}
