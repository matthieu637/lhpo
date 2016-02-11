#!/bin/bash

. ./utils/functions.bash
. ./utils/job_pool.sh

cdIntoFirstArg $@

function gonna_be_killed_parrent(){
	echo "send stop signals to sons jobs"
	get_childs_pid
	get_childs_pid | xargs -I % kill -s USR2 %
	killall $(basename $COMMAND)
}

function gonna_be_killed(){
	cd $here
	cd ..
	rm -rf $setup
	echo "I know I must stop $setup"
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
if [[ ! $MAX_CPU == "" ]] ; then
	CPU=$MAX_CPU
fi

echo "Number of thread set to $CPU."

export COMMAND=$(xml sel -t -m "/xml/command" -v @value rules.xml)
export DATA=$(xml sel -t -m "/xml/data" -v @value rules.xml)
export ARGS=$(xml sel -t -m "/xml/args" -v @value rules.xml)
export CONFIG_FILE=$(xml sel -t -m "/xml/ini_file" -v @value rules.xml)

function thread_run(){
	dir=$1
	setup=$2
	shift
	shift
	parameters="$@"

	#configuration
	cp $CONFIG_FILE $dir/$setup/
	hostname >> $dir/$setup/host
	i=1
	for parameter in $parameters ; do
		value=`echo $setup | cut -d'_' -f$i `
		sed -i "s/^\($parameter=\)[0-9.truefalse]*$/\1$value/g" $dir/$setup/$CONFIG_FILE
		i=`expr $i + 1`
	done
	
	#run
	cd $dir/$setup
	tmp_dir=`mktemp -d`
	here=`pwd`
	trap gonna_be_killed USR2
	cp $CONFIG_FILE $tmp_dir
	cp $COMMAND $tmp_dir
	if [[ ! $DATA == "" ]] ; then
		cp $DATA $tmp_dir
	fi
	args=$(cpFileFromArgs $tmp_dir "$ARGS")
	cd $tmp_dir/
	executable="./$(basename $COMMAND)"
	chmod +x $executable
	echo "$executable $args >& full.trace"
	$executable $args >& full.trace
	rm $executable

	cd $here
	mv $tmp_dir/* .
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

	cat $dir/rules.out | sed -e '1d' | shuf | while read setup ; do
		if [ $CPU -ne 1 ] ; then
			wait_free_ressources
		fi

		if [ ! -e $dir/$setup ] ; then
			mkdir $dir/$setup
			if [ $CPU -ne 1 ] ; then
				job_pool_run thread_run $dir $setup "$parameters"
			else
				thread_run $dir $setup "$parameters"
			fi
		fi
	done
done


if [ $CPU -ne 1 ]; then
	job_pool_shutdown
fi

