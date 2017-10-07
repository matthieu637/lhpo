#!/bin/bash

. ./utils/functions.bash
cdIntoFirstArg $@

project=$(basename $1)

running=0
starting=0
empty=0
finished=0

display_run=0
display_progress=0
display_done=0
display_bug=0
remove_running=0
remove_dead_node=0
reduce_weight=0
ask_upload=0
kill_running=0

LIST_RULES="rules.out"

if [ ! -e rules.xml ] ; then
	echo "rules.xml doesn't exists in $1"
	exit 1
fi

for arg in "$@"
do
	case $arg in
		"--display-bug")
			display_bug=1
		;;
		"--display-run")
			display_run=1
		;;
		"--display-progress")
			display_run=1
			display_progress=1
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
			echo "	--display-progress : displaying the stats file in each node"
			echo "	--display-bug : displaying the path of still running but seems bugged"
			echo "	--display-done : displaying the path of done runs"
			echo "	--help : print this message"
			echo "	--remove-running : remove the running directory"
			echo "	--remove-dead-node : remove the directory when the ping doesn't work"
			echo "	--reduce-weight : remove done data (copy them before!) and tricks to not compute them again"
			echo "	--ask-upload : upload running data even if not finished"
			echo "	--kill-running : kill optimizer process of all running node"
			echo "	--previous : use rules.out.old instead of rules.out if you don't want to continue an experiment"
			exit 1
		;;
		"--remove-running")
			remove_running=1
		;;
		"--reduce-weight")
			reduce_weight=1
		;;
		"--kill-running")
			kill_running=1
			display_run=1
		;;
		"--ask-upload")
			ask_upload=1
			display_run=1
		;;
		"--previous")
			LIST_RULES="rules.out.old"
		;;


	esac
done

END_FILE=$(xml sel -t -m "/xml/end_file" -v @value rules.xml)
STAT_FILE=$(xml sel -t -m "/xml/default_stat_file" -v @value rules.xml)
export CONTINUE=$(xml sel -t -v "count(/xml/continue)" rules.xml)

directories=`cat $LIST_RULES`
for dir in $directories ; do
	setups=`cat $dir/$LIST_RULES | sed -e '1d'`
	if [ $reduce_weight -eq 1 ] ; then
		echo "size before : $(du -BG -s $dir)"
	fi
        if [ $display_run -eq 1 ] ; then
                echo "$dir"
	fi


	for setup in $setups ; do
		if [ ! -e $dir/$setup ] ; then
			empty=`expr $empty + 1`
		# $dir/$setup exists
		elif [[ $CONTINUE -ne 0 && -e $dir/$setup/running && ! -e $dir/$setup/$END_FILE ]] ; then
			running=`expr $running + 1`
			if [ $remove_dead_node -eq 1 ] ; then 
				if [ -e $dir/$setup/host ] ; then
					timeout 8 ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o HashKnownHosts=no -nt -i ~/.ssh/id_rsa_clust $(cat $dir/$setup/host | tail -1 ) >& /dev/null
					if [[ !  $? -eq 0 ]] ; then
						#double check
						sleep 8
						timeout 8 ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o HashKnownHosts=no -nt -i ~/.ssh/id_rsa_clust $(cat $dir/$setup/host | tail -1 ) >& /dev/null
						if [[ !  $? -eq 0 ]] ; then
							echo "$(cat $dir/$setup/host | tail -1) down, rm $dir/$setup/running"
							rm $dir/$setup/running
						fi
					fi
				else
					echo "$dir/$setup/host doesn't exists"
				fi
			fi
			if [ $remove_running -eq 1 ] ; then
				rm $dir/$setup/running
			fi
                        if [ $display_run -eq 1 ] ; then
                            echo "$setup : $(tail -1 $dir/$setup/host)"
			fi
				
		elif [[ $CONTINUE -ne 0 && ! -e $dir/$setup/running && ! -e $dir/$setup/$END_FILE ]] ; then
			if [[ $remove_running -eq 1 && ! -e $dir/$setup/continue.data ]] ; then
				rm -rf $dir/$setup
			fi
			starting=`expr $starting + 1`
		elif [[ ( ! -e $dir/$setup/$END_FILE || ! -s $dir/$setup/$END_FILE ) && $CONTINUE -eq 0 ]] ; then
			running=`expr $running + 1`
#			cat $dir/$setup/host
			if [ $remove_running -eq 1 ] ; then
				rm -rf $dir/$setup
			fi
                        if [ $display_run -eq 1 ] ; then
			    tmp_path=$(cat $dir/$setup/host_tmp | cut -d ':' -f2)
                            echo "$setup : $(cat $dir/$setup/host) $tmp_path"
				if [ $ask_upload -eq 1 ] ; then
				  	timeout 120 ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o HashKnownHosts=no -nt -i ~/.ssh/id_rsa_clust $(cat $dir/$setup/host) "cp $tmp_path/* ~/home_grid5000/$project/$dir/$setup/"
				fi
				if [ $kill_running -eq 1 ] ; then
				  	timeout 15 ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o HashKnownHosts=no -nt -i ~/.ssh/id_rsa_clust $(cat $dir/$setup/host) "killall -s USR2 optimizer.bash"
				fi
				if [ $display_progress -eq 1 ] ; then
				  	timeout 15 ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o HashKnownHosts=no -nt -i ~/.ssh/id_rsa_clust $(cat $dir/$setup/host) "if [ -e $tmp_path/0.testing.data ] ; then tail -1 $tmp_path/0.testing.data ; elif [ -e $tmp_path/0.learning.data ] ; then tail -1 $tmp_path/0.learning.data ; fi"
				fi
                        fi
                        if [ $display_bug -eq 1 ] ; then
				if [[ -e $dir/$setup/host && $(ls -l $dir/$setup/ | wc -l) -gt 3 ]] ; then
                        		echo "$setup : $(cat $dir/$setup/host)"
					#rm -rf $dir/$setup
				fi
                        fi
			if [ $remove_dead_node -eq 1 ] ; then 
				if [ -e $dir/$setup/host ] ; then
					timeout 10 ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o HashKnownHosts=no -nt -i ~/.ssh/id_rsa_clust $(cat $dir/$setup/host) >& /dev/null
					if [[ !  $? -eq 0 ]] ; then
						#double check
						sleep 15
						timeout 10 ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o HashKnownHosts=no -nt -i ~/.ssh/id_rsa_clust $(cat $dir/$setup/host | tail -1) >& /dev/null
						if [[ !  $? -eq 0 ]] ; then
							echo "$(cat $dir/$setup/host | tail -1) down, rm $dir/$setup"
							rm -r $dir/$setup
						fi
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

			if [ $reduce_weight -eq 1 ] ; then
				#outdated code for irace
				#if [ -s $dir/$setup/0.learning.data ] ; then
				#	#for irace
				#	zcat $dir/$setup/0.learning.data | sed 's/  / /g' | cut -d' ' -f7 | sort -rn | head -n 1 | xargs -I % echo '-1 * %' | bc > $dir/$setup/reduced.0.learning.data
				#fi
				#find $dir/$setup/ -type f -not -name "$END_FILE" -not -name "reduced.0.learning.data" -print0 | xargs -I % -0 rm %
				find $dir/$setup/ -type f -not -name "$END_FILE" -not -name "continue.data" -print0 | xargs -I % -0 rm %
			fi
		fi
	done

	if [ $reduce_weight -eq 1 ] ; then
		echo "size after : $(du -BG -s $dir)"
	fi
done

echo "running : ${running}"
echo "to do : ${empty}"
echo "done : ${finished}"

if [ $CONTINUE -ne 0 ] ; then
	echo "starting : ${starting}"
fi


