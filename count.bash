#!/bin/bash

. ./utils/functions.bash
cdIntoFirstArg $@

running=0
empty=0
finished=0

END_FILE=$(xml sel -t -m "/xml/end_file" -v @value rules.xml)

directories=`cat rules.out`
for dir in $directories ; do
	setups=`cat $dir/rules.out | sed -e '1d'`
	for setup in $setups ; do
		if [ ! -e $dir/$setup ] ; then
			empty=`expr $empty + 1`
		elif [[ -e $dir/$setup && ! -e $dir/$setup/$END_FILE ]] ; then
			running=`expr $running + 1`
#			cat $dir/$setup/host
#			echo $setup
		elif [[ -e $dir/$setup && -e $dir/$setup/$END_FILE ]] ; then
			finished=`expr $finished + 1`
		fi
	done
done

echo "running : ${running}"
echo "to do : ${empty}"
echo "done : ${finished}"

