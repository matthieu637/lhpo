#!/bin/bash

directories=`cat rules.out`
for dir in $directories ; do
	echo "############################ $dir #####################################"
	cp stats.m $dir
	cd $dir
	chmod +x ./stats.m
	./stats.m
	cd ..
done

