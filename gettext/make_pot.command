#!/bin/bash
MY_DIRNAME=$(dirname $0)
cd $MY_DIRNAME

DSRC="../source/app.d ../source/castle.d ../source/edgeoftown.d ../source/dungeon.d ../source/battle.d ../source/cMember.d ../source/cParty.d ../source/cMonster.d ../source/cMonsterParty.d ../source/cMonsterParty.d ../source/cMap.d ../source/cEvent.d"
POT=daemon.pot

xgettext -k"_" -k"N_:1,2" --from-code=UTF-8 $DSRC -o $POT
