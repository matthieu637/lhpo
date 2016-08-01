#!/bin/bash

. ./utils/functions.bash
cdIntoFirstArg $@

if [ ! -e rules.xml ] ; then
	echo "rules.xml doesn't exists in $1"
	exit 1
fi

DEFAULT_STAT_FILE=$(xml sel -t -m "/xml/default_stat_file" -v @value rules.xml)

directories=`cat rules.out`
for dir in $directories ; do
	echo "$dir :"
	find $dir -type f -name "$DEFAULT_STAT_FILE" | xargs -L 1 bash -c 'echo $(zcat $1 | wc -l) -- $1' argv | sort -n

done

