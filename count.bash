#!/bin/bash

. ./utils/functions.bash
cdIntoFirstArg $@

running=0
empty=0
finished=0

display_run=0
display_done=0
remove_running=0
remove_dead_node=0

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
		"--display-done")
			display_done=1
		;;
		"--remove-dead-node")
			remove_dead_node=1
		;;
		"-h"|"--help")
			echo "usage $0 : <directory with rules.xml> <options>"
			echo "options :"
			echo "	--display-run : displaying the path of still running"
			echo "	--display-done : displaying the path of done runs"
			echo "	--help : print this message"
			echo "	--remove-running : remove the running directory"
			echo "	--remove-dead-node : remove the directory when the ping doesn't work"
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
		elif [[ ! -e $dir/$setup/$END_FILE || ! -s $dir/$setup/$END_FILE ]] ; then
			running=`expr $running + 1`
#			cat $dir/$setup/host
			if [ $remove_running -eq 1 ] ; then
				rm -rf $dir/$setup
			fi
                        if [ $display_run -eq 1 ] ; then
                            echo "$setup : $(cat $dir/$setup/host)"
                        fi
			if [ $remove_dead_node -eq 1 ] ; then 
				if [ -e $dir/$setup/host ] ; then
					timeout 5 ssh -o StrictHostKeyChecking=no -o HashKnownHosts=no -o BatchMode=yes -n -i ~/.ssh/id_rsa_clust $(cat $dir/$setup/host) >& /dev/null
					if [[ !  $? -eq 0 ]] ; then
						echo "$(cat $dir/$setup/host) down, rm $dir/$setup"
						rm -r $dir/$setup
					fi
				else
					echo "$dir/$setup/host doesn't exists"
				fi
			fi
		elif [[ -e $dir/$setup/$END_FILE ]] ; then
			finished=`expr $finished + 1`
                        if [ $display_done -eq 1 ] ; then
                            echo $setup
                        fi
		fi
	done
done

echo "running : ${running}"
echo "to do : ${empty}"
echo "done : ${finished}"

