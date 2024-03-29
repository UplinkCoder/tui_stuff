#!/usr/bin/env bash
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR
if [ ! -f libtermbox.a ] || [ "$1" == "-f" ]; then
    echo "Building Termbox"
    rm -rf termbox-master
    curl -L --progress-bar https://github.com/nsf/termbox/archive/master.tar.gz > termbox.tar.gz
    tar -xf termbox.tar.gz
    rm termbox.tar.gz
    cd termbox-master
    ./waf configure
    ./waf install --targets=termbox_static --destdir=.
    mv build/src/libtermbox.a ..
    cd ..
#    rm -rf termbox-master
fi
