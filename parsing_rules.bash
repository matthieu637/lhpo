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
	echo -n '' > $fold/mixer
	for constraint in "$constraints" ; do
		echo "$constraint" >> $fold/mixer 
	done

	if [ $nconst -eq 0 ] ; then
		echo "test=True;" > $fold/mixer
	else
		sed -i "s/&lt;/</g" $fold/mixer
		sed -i "s/&gt;/>/g" $fold/mixer
		sed -i "s/\([A-Za-z0-9_]\+\)/dico['\1'][i]/g" $fold/mixer
		sed -i "s/^/test=/" $fold/mixer
		sed -i "s/$/;/" $fold/mixer
	fi
	
	tmp=`mktemp`
	cat $fold/rules.out | $LHPO_PATH/utils/constraints.py $fold/mixer > $tmp
	mv $tmp $fold/mixer
	mv $fold/mixer $fold/rules.out
        sed -i "s/'//g" $fold/rules.out
	sed -i "s/[[]//g" $fold/rules.out
	sed -i "s/[]]//g" $fold/rules.out
	sed -i '2,$'"s/ //g" $fold/rules.out
	sed -i '2,$'"s/[,]/_/g" $fold/rules.out
	sed -i '1'"s/[,]//g" $fold/rules.out
	sed -i "s/_$//g" $fold/rules.out

done

echo "$folds" | sed -e 's/ //g' > rules.out

