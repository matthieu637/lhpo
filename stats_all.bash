#!/bin/bash

. ./utils/functions.bash
cdIntoFirstArg $@

STAT_FILE="learning.data"

if [ ! -e rules.out ] ; then
	echo "Please run parsing_rules first"
	exit 1
fi

directories=`cat rules.out`
for dir in $directories ; do
	echo "############################ $dir #####################################"
	cp $LHPO_PATH/utils/stats.m $dir
	cp $LHPO_PATH/utils/stats2.m $dir
	cp $LHPO_PATH/utils/load_dirs.m $dir

	cd $dir
	chmod +x ./stats.m
	chmod +x ./stats2.m

	./stats.m $STAT_FILE
	./stats2.m $STAT_FILE
	
	#rm ./stats.m
	cd ..
done

