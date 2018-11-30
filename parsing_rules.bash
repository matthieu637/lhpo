#!/bin/bash

. ./utils/functions.bash
cdIntoFirstArg $@

if [ ! -e rules.xml  ] ; then
	echo "rules.xml missing."
	exit 1
fi

folds=`$XML sel -t -m "/xml/fold" -v @name -n rules.xml`
export CONFIG_FILES=$($XML sel -t -m "/xml/ini_file" -v @value rules.xml)

for fold in $folds ; do
	echo "found a new fold : $fold"
	
	if [ ! -e $fold ] ; then
		mkdir $fold
	fi

	irace=$($XML sel -t -v "count(/xml/fold[@name='$fold' and @type='irace'])" rules.xml)
	if [[ $irace -eq 1 && -e $fold/rules.out && $(wc -l $fold/rules.out | cut -f1 -d' ') -ne 1 ]] ; then
		echo "$fold/rules.out is already populated be careful!"
		echo "Please run ./clear.bash first if you want to remove rules."
		continue
	fi
	params=`$XML sel -t -m "/xml/fold[@name='$fold']/param" -v @name -n rules.xml`
	fold_mixer=`mktemp`
	fold_rules=`mktemp`
	echo $params > $fold_rules.out
	echo -n '' > $fold_mixer

	for param in $params ; do
		values=`$XML sel -t -m "/xml/fold[@name='$fold']/param[@name='$param']" -v @values -n rules.xml`
		if [[ $param != "run" && $(grep -e "^$param=" $CONFIG_FILES | wc -l) -eq 0 ]] ; then
			echo "$param not defined in $CONFIG_FILES"
			exit 1
		fi
		echo $values >> $fold_mixer
	done

	#enumeration
	cat $fold_mixer | $LHPO_PATH/utils/enumerate.py >> $fold_rules.out
	sed -i "s/'//g" $fold_rules.out
	sed -i "s/[[]//g" $fold_rules.out
	sed -i "s/[]]//g" $fold_rules.out
	sed -i '2,$'"s/ //g" $fold_rules.out
	sed -i "s/[,]/_/g" $fold_rules.out


	#constraining
	nconst=`$XML sel -t -m "/xml/fold[@name='$fold']/rule" -v @constraint -n rules.xml | wc -l`
	constraints=`$XML sel -t -m "/xml/fold[@name='$fold']/rule" -v @constraint -n rules.xml`
	constraints_type=`$XML sel -t -m "/xml/fold[@name='$fold']/rule" -v @type -n rules.xml`

	#clear old file
	echo -n '' > $fold_mixer
	if [ $nconst -eq 0 ] ; then
		echo "True" > $fold_mixer
	else
		i=0
		read -a constraints_type <<< "$constraints_type"
		for constraint in "$constraints" ; do
			if [[ "${constraints_type[$i]}" == 'python' ]] ; then
				echo "$constraint" >> $fold_mixer
#			elif [[ "${constraints_type[$i]}" == 'bool' ]] ; then
#				echo ""
			else
				echo "unkown type constraint : ${constraints_type[$i]}"
				exit 1
			fi

			i=`expr $i + 1`
		done
	
		sed -i "s/&lt;/</g" $fold_mixer
		sed -i "s/&gt;/>/g" $fold_mixer
#		sed -i "s/\([A-Za-z0-9_]\+\)/dico['\1'][i]/g" $fold_mixer
		
		sed -i "s/^/(/" $fold_mixer
		sed -i "s/$/) and /" $fold_mixer

		mv $fold_mixer $fold_mixer.2
		paste -s $fold_mixer.2 > $fold_mixer
		rm $fold_mixer.2
		sed -i 's/ and $//' $fold_mixer
	fi
	#to debug:
#	cp $fold_mixer $fold/debug.constraints
#	cp $fold_rules.out $fold/debug.prerule
	
	#execute constraints
	tmp=`mktemp`
	nbline=$(wc -l $fold_rules.out | sed -e 's/^\([0-9]*\) .*/\1/')
	$LHPO_PATH/utils/constraints.py $fold_mixer $fold_rules.out $nbline > $tmp

	mv $tmp $fold_mixer
	mv $fold_mixer $fold_rules.out
        sed -i "s/'//g" $fold_rules.out
	sed -i "s/[[]//g" $fold_rules.out
	sed -i "s/[]]//g" $fold_rules.out
	sed -i '2,$'"s/ //g" $fold_rules.out
	sed -i '2,$'"s/[,]/_/g" $fold_rules.out
	sed -i '1'"s/[,]//g" $fold_rules.out

	if [ $irace -eq 1 ] ; then
		sed -ni '1p;' $fold_rules.out
		if [ ! -e $fold.irout ] ; then
			mkdir $fold.irout
		fi
		echo "run irace now and then optimizer in a loop"
	else
		echo "$(wc -l $fold_rules.out |cut -d ' ' -f1) runs to do"
	fi

	mv $fold_rules.out $fold/rules.out &> /dev/null
done

echo "$folds" | sed -e 's/ //g' > rules.out

