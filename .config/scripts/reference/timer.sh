#!/bin/sh

# does not work with ion because PROMPT function is a separate process with
# no way to export to parent process environment
# only way is to use files, but i would rather not
# would have to keep PID record of term to separate timers

test -n "$custom_prompt_timer" && export custom_prompt_timer="$(date +%s)"
echo "$custom_prompt_timer"
custom_prompt_timer="$(date +%s)"
#custom_prompt_timer="$((`TZ=GMT0 date \
#  + "((%Y-1600))*365+(%Y-1600)/4-(%Y-1600)/100+(%Y-1600)/400+%j-135410)\
#  * 86400 + %H * 3600 + %M * 60 + %S"`))"


export custom_prompt_timer
