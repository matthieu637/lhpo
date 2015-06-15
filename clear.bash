#!/bin/bash

. ./utils/functions.bash
cdIntoFirstArg $@

if [ ! -e rules.out ] ; then
	exit 0
fi

directories=`cat rules.out`
for dir in $directories ; do
	rm -r $dir
done

rm rules.out
