#!/bin/bash
MY_DIRNAME=$(dirname $0)
cd $MY_DIRNAME

DSRC="../source/app.d ../source/castle.d ../source/edgeoftown.d"
POT=daemon.pot

xgettext -k"_" --from-code=UTF-8 $DSRC -o $POT
