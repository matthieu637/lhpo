#!/bin/bash

. ./utils/functions.bash
cdIntoFirstArg $@

if [ ! -e rules.xml  ] ; then
	echo "rules.xml missing."
	exit 1
fi

folds=`xml sel -t -m "/xml/fold" -v @name -n rules.xml`

for fold in $folds ; do
	echo "found a new fold : $fold"
	
	if [ ! -e $fold ] ; then
		mkdir $fold
	fi

	irace=$(xml sel -t -v "count(/xml/fold[@name='$fold' and @type='irace'])" rules.xml)
	params=`xml sel -t -m "/xml/fold[@name='$fold']/param" -v @name -n rules.xml`
	echo $params > $fold/rules.out
	echo -n '' > $fold/mixer

	for param in $params ; do
		values=`xml sel -t -m "/xml/fold[@name='$fold']/param[@name='$param']" -v @values -n rules.xml`
		echo $values >> $fold/mixer
	done

	#enumeration
	cat $fold/mixer | $LHPO_PATH/utils/enumerate.py >> $fold/rules.out
	sed -i "s/'//g" $fold/rules.out
	sed -i "s/[[]//g" $fold/rules.out
	sed -i "s/[]]//g" $fold/rules.out
	sed -i '2,$'"s/ //g" $fold/rules.out
	sed -i "s/[,]/_/g" $fold/rules.out


	#constraining
	nconst=`xml sel -t -m "/xml/fold[@name='$fold']/rule" -v @constraint -n rules.xml | wc -l`
	constraints=`xml sel -t -m "/xml/fold[@name='$fold']/rule" -v @constraint -n rules.xml`
	constraints_type=`xml sel -t -m "/xml/fold[@name='$fold']/rule" -v @type -n rules.xml`

	#clear old file
	echo -n '' > $fold/mixer
	if [ $nconst -eq 0 ] ; then
		echo "True" > $fold/mixer
	else
		i=0
		read -a constraints_type <<< "$constraints_type"
		for constraint in "$constraints" ; do
			if [[ "${constraints_type[$i]}" == 'python' ]] ; then
				echo "$constraint" >> $fold/mixer
#			elif [[ "${constraints_type[$i]}" == 'bool' ]] ; then
#				echo ""
			else
				echo "unkown type constraint : ${constraints_type[$i]}"
				exit 1
			fi

			i=`expr $i + 1`
		done
	
		sed -i "s/&lt;/</g" $fold/mixer
		sed -i "s/&gt;/>/g" $fold/mixer
#		sed -i "s/\([A-Za-z0-9_]\+\)/dico['\1'][i]/g" $fold/mixer
		
		sed -i "s/^/(/" $fold/mixer
		sed -i "s/$/) and /" $fold/mixer

		mv $fold/mixer $fold/mixer.2
		paste -s $fold/mixer.2 > $fold/mixer
		sed -i 's/ and $//' $fold/mixer
	fi
	#to debug:
#	cp $fold/mixer $fold/debug.constraints
#	cp $fold/rules.out $fold/debug.prerule
	
	#execute constraints
	tmp=`mktemp`
	nbline=$(wc -l $fold/rules.out | sed -e 's/^\([0-9]*\) .*/\1/')
	$LHPO_PATH/utils/constraints.py $fold/mixer $fold/rules.out $nbline > $tmp

	mv $tmp $fold/mixer
	mv $fold/mixer $fold/rules.out
        sed -i "s/'//g" $fold/rules.out
	sed -i "s/[[]//g" $fold/rules.out
	sed -i "s/[]]//g" $fold/rules.out
	sed -i '2,$'"s/ //g" $fold/rules.out
	sed -i '2,$'"s/[,]/_/g" $fold/rules.out
	sed -i '1'"s/[,]//g" $fold/rules.out

	if [ $irace -eq 1 ] ; then
		sed -ni '1p;' $fold/rules.out
		if [ ! -e $fold.irout ] ; then
			mkdir $fold.irout
		fi
		echo "run irace now and then optimizer in a loop"
	else
		echo "$(wc -l $fold/rules.out) runs to do"
	fi
done

echo "$folds" | sed -e 's/ //g' > rules.out

