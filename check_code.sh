#!/bin/sh

# http://mywiki.wooledge.org/Bashism
# https://wiki.ubuntu.com/DashAsBinSh

epm assure shellcheck || exit
#epm assure checkbashisms || exit

EXCL=-eSC2086,SC2039,SC2034,SC2068,SC2155

if [ -n "$1" ] ; then
    shellcheck $EXCL "$1"
    #checkbashisms -f "$1"
    exit
fi

#checkbashisms -f *.sh
#checkbashisms -f Makefile

shellcheck $EXCL *.sh
