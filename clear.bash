#!/bin/bash

. ./utils/functions.bash
cdIntoFirstArg $@

if [ ! -e rules.out ] ; then
	exit 0
fi

directories=`cat rules.out`
for dir in $directories ; do
	rm -rf $dir
	if [ -e $dir.irout ] ; then
		rm -rf $dir.irout
	fi
done

rm rules.out
