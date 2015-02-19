#!/bin/bash

END_FILE="time_elapsed"

function report(){
directories=`cat rules.out`
for dir in $directories ; do
	cat $dir/rules.out | sed -e '1d' | while read setup ; do
		if [[ -e $dir/$setup && ! -e $dir/$setup/$END_FILE  ]] ; then
			du -s $dir/$setup >> $1
		fi
	done
done
}

reporter=`mktemp`
report $reporter

sleep 3m

reporter2=`mktemp`
report $reporter2

echo ${reporter}
echo ${reporter2}

echo "want to remove : "
grep -Fx -f ${reporter} ${reporter2} 
grep -Fx -f ${reporter} ${reporter2} | cut -d'	' -f2 | xargs rm -r


rm ${reporter}

echo '' > $reporter
report $reporter

echo "\nkeeps :"
cat $reporter

rm $reporter
rm ${reporter2}
