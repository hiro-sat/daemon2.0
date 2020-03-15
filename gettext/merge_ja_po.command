#!/bin/bash
MY_DIRNAME=$(dirname $0)
cd $MY_DIRNAME

INPUT_FROM=ja.po
INPUT_TO=daemon.pot

mv $INPUT_FROM _$INPUT_FROM
msgmerge _$INPUT_FROM $INPUT_TO -o $INPUT_FROM
