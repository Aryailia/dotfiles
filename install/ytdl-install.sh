#!/usr/bin/sh

require() { command -v "$1" >/dev/null 2>&1; }

prerequisite=""
require 'curl'    || prerequisite="${prerequisite} curl, "
require 'ffmpeg'  || prerequisite="${prerequisite} ffmpeg, "
require 'python2' || prerequisite="${prerequisite} python2, "
require 'python'  || prerequisite="${prerequisite} python(3), "

[ -n "$prerequisite" ] && { echo "You must install ${prerequisite}"; exit 1; }
pip install --upgrade youtube-dl
require 'youtube-dl' && echo 'Success'
