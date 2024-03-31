#!/bin/bash
MY_DIRNAME=$(dirname $0)
cd $MY_DIRNAME

FROM=list_gettext
POT=daemon.pot

# xgettext -k"_" -k"N_:1,2" --from-code=UTF-8 $DSRC -o $POT
xgettext -k"_" -k"N_:1,2" --from-code=UTF-8 --files-from=$FROM -o $POT
