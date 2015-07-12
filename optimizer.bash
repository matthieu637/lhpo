#!/bin/bash

. ./utils/functions.bash
. ./utils/job_pool.sh

cdIntoFirstArg $@

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
if [[ $# -eq 2 && $2 -le $max_cpu && $2 -gt 0 ]] ; then
	CPU=$2
else
	CPU=$max_cpu
fi
echo "Number of thread set to $CPU."

export COMMAND=$(xml sel -t -m "/xml/command" -v @value rules.xml)
export ARGS=$(xml sel -t -m "/xml/args" -v @value rules.xml)
export CONFIG_FILE=$(xml sel -t -m "/xml/ini_file" -v @value rules.xml)

function thread_run()
{
directories=`cat rules.out`
for dir in $directories ; do
	cat $dir/rules.out | sed -e '1d' | while read setup ; do
		if [ ! -e $dir/$setup ] ; then
			mkdir $dir/$setup
			
			#configuration
			cp $CONFIG_FILE $dir/$setup/
			hostname >> $dir/$setup/host
			i=1
			for parameter in $( head -1 $dir/rules.out ) ; do
				value=`echo $setup | cut -d'_' -f$i `
				sed -i "s/^\($parameter=\)[0-9.]*$/\1$value/g" $dir/$setup/$CONFIG_FILE
				i=`expr $i + 1`
			done
	
			#run
			cd $dir/$setup
			tmp_dir=`mktemp -d`
			here=`pwd`
			cp $CONFIG_FILE	$tmp_dir
			cp $COMMAND $tmp_dir
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
		fi
	done
done
}

if [ $CPU -ne 1 ]; then

	job_pool_init $CPU 0
	for i in $(seq 0 1 ${CPU})
	do
		job_pool_run thread_run
		sleep 2
	done

	job_pool_wait
	job_pool_shutdown

else
	thread_run
fi

