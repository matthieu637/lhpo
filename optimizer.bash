#!/bin/bash

COMMAND="../../../build/default/exp/kbexploit/RLNNACST_novisu --map ../../../exp/kbexploit/data/arena/small/d_b2_c2.pbm --instances 0 --instances 1 --na 17 --actions ../../../exp/kbexploit/data/actions/human_linear_s15_n17 --state ../../../exp/kbexploit/data/states/final_52human"
CONFIG_FILE="configRL.ini"

directories=`cat rules.out`
for dir in $directories ; do
	cat $dir/rules.out | sed -e '1d' | while read setup ; do
		if [ ! -e $dir/$setup ] ; then
			mkdir $dir/$setup
			
			#configuration
			cp $CONFIG_FILE $dir/$setup/
			i=1
			for parameter in $( head -1 $dir/rules.out ) ; do
				value=`echo $setup | cut -d'_' -f$i `
				sed -i "s/^\($parameter=\)[0-9.]*$/\1$value/g" $dir/$setup/$CONFIG_FILE
				i=`expr $i + 1`
			done
	
			#run
			cd $dir/$setup
			$COMMAND
			cd ../..
		fi
	done
done

