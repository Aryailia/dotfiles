#!/usr/bin/sh

curl http://vicerveza.homeunix.net/~viric/soft/ts/ts-1.0.tar.gz -o ts-1.0.tar.gz
tar -xvzf ts-1.0.tar.gz
cd "ts-1.0"
make install PREFIX="$PREFIX"
