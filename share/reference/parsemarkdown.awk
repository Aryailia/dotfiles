#!/usr/bin/awk -f
#BEGIN { }

# Convert from windows newline (CRLF) to unix newlines (LF)
{gsub(/\r/, "");}
//{}
1
