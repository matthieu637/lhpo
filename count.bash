#!/bin/bash

. ./utils/functions.bash
cdIntoFirstArg $@

running=0
empty=0
finished=0

display_run=0
remove_running=0

if [ ! -e rules.xml ] ; then
	echo "rules.xml doesn't exists in $1"
	exit 1
fi

for arg in "$@"
do
	case $arg in
		"--display-run")
			display_run=1
		;;
		"-h"|"--help")
			echo "usage $0 : <directory with rules.xml> <options>"
			echo "options :"
			echo "	--display-run : displaying the path of still running"
			echo "	--help : print this message"
			echo "	--remove-running : remove the running directory"
			exit 1
		;;
		"--remove-running")
			remove_running=1
		;;
	esac
done

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
			if [ $remove_running -eq 1 ] ; then
				rm -rf $dir/$setup
			fi
                        if [ $display_run -eq 1 ] ; then
                            echo $setup
                        fi
		elif [[ -e $dir/$setup && -e $dir/$setup/$END_FILE ]] ; then
			finished=`expr $finished + 1`
		fi
	done
done

echo "running : ${running}"
echo "to do : ${empty}"
echo "done : ${finished}"

