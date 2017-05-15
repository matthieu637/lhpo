#!/bin/bash

. ./utils/functions.bash
. ./utils/job_pool.sh

cdIntoFirstArg $@

#parrent is locked on wait_for_ressource
#sons receive directly the signal
function gonna_be_killed_parrent(){
	echo "all stop received, sleep a little"
#	get_childs_pid
#	get_childs_pid | xargs -I % kill -s USR2 %
	sleep 50s
	exit 0
}

function gonna_be_killed(){
	if [ $CONTINUE -ne 0 ] ; then
		rm $here/running

		#cp -r * $here
		if [ -e continue.data ] ; then
			rm continue.data
		fi

		ls continue.*.data >& /dev/null
		if [ $? -eq 0 ] ; then
			tar cf - continue.*.data | gzip - > continue.data
			rm continue.*.data
			cp continue.data $here/continue.data.tmp >& /dev/null
                        if [ -e $here/continue.data ] ; then
                        	mv $here/continue.data $here/continue.data.old
                        fi
			mv $here/continue.data.tmp $here/continue.data
		fi
	elif [ -e $here ] ; then
		cd $here
		cd ..
		rm -rf $setup
	fi

	echo "I know I must stop $setup"
	killall $(basename $COMMAND)
	if [ $CPU -ne 1 ] ; then
		#unlock father
		unlock_wait
	fi
	exit 0
}

function cpFileFromArgs(){
        destination=$1
        args=$2

        read -a array <<< "$args"
        for element in "${array[@]}"
        do
            if [ -e "$element" ] ; then
                cp $element $destination
                echo -n "$(basename $element) "
            else
                echo -n "$element "
            fi
        done
}

if [ ! -e rules.out ] ; then
	echo "Please run parsing_rules first"
	exit 1
fi

max_cpu=$(nbcpu)
max_cpu=$(expr $max_cpu - 1)
if [[ $# -eq 2 && $2 -le $max_cpu && $2 -gt 0 ]] ; then
	CPU=$2
else
	CPU=$max_cpu
fi

export MAX_CPU=$(xml sel -t -m "/xml/max_cpu" -v @value rules.xml)
if [[ ! $MAX_CPU == "" && $MAX_CPU -lt $CPU ]] ; then
	CPU=$MAX_CPU
fi

echo "Number of thread set to $CPU."

export COMMAND=$(xml sel -t -m "/xml/command" -v @value rules.xml)
export DATA=$(xml sel -t -m "/xml/data" -v @value rules.xml)
export RM_DATA=$(xml sel -t -m "/xml/rm_data" -v @value rules.xml)
export ARGS=$(xml sel -t -m "/xml/args" -v @value rules.xml)
export CONFIG_FILES=$(xml sel -t -m "/xml/ini_file" -v @value rules.xml)
export COMPRESSED_DATA=$(xml sel -t -m "/xml/compressed_data" -v @value rules.xml)
export END_FILE=$(xml sel -t -m "/xml/end_file" -v @value rules.xml)
export CONTINUE=$(xml sel -t -v "count(/xml/continue)" rules.xml)

if [ ! -e $COMMAND ] ; then
	echo "$COMMAND doesn't exists"
	exit 1
fi

function thread_run(){
	dir=$1
	setup=$2
	shift
	shift
	parameters="$@"

	#configuration
	cp $CONFIG_FILES $dir/$setup/
	hostname >> $dir/$setup/host
	i=1
	for parameter in $parameters ; do
		value=`echo $setup | cut -d'_' -f$i `

		#if parameter is file specific
		if [ $(echo $parameter | grep -e ':' | wc -l) -eq 1 ] ; then
			configf=$(echo $parameter | cut -d ':' -f1)
			parameter=$(echo $parameter | cut -d ':' -f2)
			sed -i "s/^\($parameter=\)[0-9,:.truefalse-]*$/\1$value/g" $dir/$setup/$configf
			
		else
			for configf in $CONFIG_FILES ; do
				sed -i "s/^\($parameter=\)[0-9,:.truefalse-]*$/\1$value/g" $dir/$setup/$configf
			done
		fi
		i=`expr $i + 1`
	done
	
	#run
	cd $dir/$setup
	tmp_dir=`mktemp -d`
	echo "$(hostname):$tmp_dir" >> host_tmp
	here=`pwd`
	trap gonna_be_killed USR2
	if [ $CONTINUE -ne 0 ] ; then
		#cp -r * $tmp_dir/
		if [ -e continue.data ] ; then
			cp continue.data $tmp_dir/
			cd $tmp_dir/
			gzip -d -S .data continue.data
			if [ $? -ne 0 ] ; then #archive corrupted
				if [ -e $here/continue.data.old ] ; then
					mv $here/continue.data.old $here/continue.data
					cp $here/continue.data .
					gzip -d -S .data continue.data
					if [ $? -ne 0 ] ; then #old archive also corrupted
						rm $here/continue.data
					else
						#saved with old data
						tar -xf continue
						rm continue
					fi
				else
					#cannot recover acts as no data before
					rm $here/continue.data
					rm continue.data
				fi
			else
				tar -xf continue
				rm continue
			fi
			cd $here
		fi
	fi
	cp $CONFIG_FILES $tmp_dir
	cp $COMMAND $tmp_dir
	if [[ ! $DATA == "" ]] ; then
		cp $DATA $tmp_dir
		cd $tmp_dir
		for data_file in $DATA ; do
			if [[ `file $data_file -b | cut -d ' ' -f1` == 'XZ' ]] ; then
				tar -xJf $(basename $data_file)
				rm $(basename $data_file)
			fi
		done
		cd $here
	fi
	args=$(cpFileFromArgs $tmp_dir "$ARGS")
        if [ $CONTINUE -ne 0 ] ; then
                args="$args --continue" 
        fi
	cd $tmp_dir/
	executable="./$(basename $COMMAND)"
	chmod +x $executable
	echo "$executable $args >& full.trace"

	$executable $args >& full.trace &
	last_pid=$!
	if [ $CONTINUE -ne 0 ] ; then
		counter=0
		while [ 1 ] ; do
			sleep 1m &
			wait $!

			#test that exec is not finished
			kill -0 $last_pid >& /dev/null
			if [ $? -ne 0 ] ; then
				break
			fi

			#upload each 50 min
			if [ $counter -ge 50 ] ; then
				counter=0
				#cp -r * $here/
				if [ -e continue.data ] ; then
					rm continue.data
				fi
				
				ls continue.*.data >& /dev/null
				if [ $? -eq 0 ] ; then
					tar cf - continue.*.data | gzip -9 - > continue.data
					rm continue.*.data
					cp continue.data $here/continue.data.tmp
					if [ -e $here/continue.data ] ; then
						mv $here/continue.data $here/continue.data.old
					fi
					mv $here/continue.data.tmp $here/continue.data
				fi
			fi
			counter=`expr $counter + 1`
		done
	fi

	wait $last_pid
	result=$?

	echo $result >> full.trace

	if [ $result -ne 0 ] ; then
		echo "FAILED : ($tmp_dir)"
		cat full.trace
		rm $here/host
		rm $here/running
		for configf in $CONFIG_FILES ; do
			rm $here/$configf
		done
		if [ $CONTINUE -ne 0 ] ; then
			rm $here/continue.data
			if [ -e $here/continue.data.old ] ; then 
				#data can be saved
				mv $here/continue.data.old $here/continue.data
				#don't rmdir 
				exit 0
			fi
		fi
		rmdir $here
		exit 0
	elif [ $CONTINUE -ne 0 ] ; then
		ls continue.*.data >& /dev/null
		if [ $? -eq 0 ] ; then
			tar cf - continue.*.data | gzip -9 - > continue.data
			rm continue.*.data
			cp continue.data $here/continue.data.tmp
			if [ -e $here/continue.data ] ; then
				mv $here/continue.data $here/continue.data.old
			fi
			mv $here/continue.data.tmp $here/continue.data
		fi

	fi
	rm $executable

	if [[ ! $RM_DATA == "" ]] ; then
		rm -rf $RM_DATA
	fi

	if [[ ! $COMPRESSED_DATA == "" ]] ; then
	 	for cfile in $COMPRESSED_DATA ; do
			gzip --best $cfile
			mv $cfile.gz $cfile
		done
	fi

	if [ -e $here ] ; then
		cd $here
		if [[ -e $here && $CONTINUE -ne 0 ]] ; then
			cp $CONFIG_FILES $tmp_dir/
			cp host $tmp_dir/
			#rm -rf * #might be too dangerous if $here don't exist anymore
		fi
		mv $tmp_dir/* .
		if [ -e running ] ; then
			rm running
		fi
	fi
	rmdir $tmp_dir
	cd ../..
}

if [ $CPU -ne 1 ]; then
	job_pool_init $CPU 0
	trap gonna_be_killed_parrent USR2
fi

#full passage of %100
directories=`cat rules.out`
for dir in $directories ; do
	parameters=`head -1 $dir/rules.out`

	all_todo=`mktemp`
	cat $dir/rules.out | sed -e '1d' | shuf > $all_todo
	for setup in $(cat $all_todo) ; do
		if [ $CPU -ne 1 ] ; then
			wait_free_ressources
		fi

		if [ ! -e $dir/$setup ] ; then
			mkdir $dir/$setup
			touch $dir/$setup/running
			if [ $CPU -ne 1 ] ; then
				job_pool_run thread_run $dir $setup "$parameters"
			else
				thread_run $dir $setup "$parameters"
			fi
		elif [[ $CONTINUE -ne 0 && ! -e $dir/$setup/$END_FILE && ! -e $dir/$setup/running ]] ; then
			touch $dir/$setup/running
                        if [ $CPU -ne 1 ] ; then
                                job_pool_run thread_run $dir $setup "$parameters"
                        else
                                thread_run $dir $setup "$parameters"
                        fi
		fi
	done
	rm $all_todo
done


if [ $CPU -ne 1 ]; then
	job_pool_shutdown
fi

