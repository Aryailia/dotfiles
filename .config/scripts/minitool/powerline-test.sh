#!/bin/bash
# !:console bash %self
# White on red bg 'hello', powerline transition, white on cyan bg 'there'
printf '%s' $'\033[1;37;41m hello \033[1;31;46m\uE0B0 \033[1;37mthere '
