#!/bin/sh
# This is what the alias should look like
podman run -v $PWD:/root/opt -it --rm ebook-convert:latest ./convert.sh "${1}" "${2}"
