#!/bin/bash

COMMAND="../../../build/default/exp/kbexploit/RLNNACST_novisu"
ARGS="--map ../../../exp/kbexploit/data/arena/small/d_b2_c2.pbm --instances 0 --instances 1 --na 17 --actions ../../../exp/kbexploit/data/actions/human_linear_s15_n17 --state ../../../exp/kbexploit/data/states/final_52human"
CONFIG_FILE="config.ini"

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

