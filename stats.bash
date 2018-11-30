#!/bin/bash

. ./utils/functions.bash
cdIntoFirstArg $@

STAT_FILE=$($XML sel -t -m "/xml/default_stat_file" -v @value rules.xml)
Y_MIN=$($XML sel -t -m "/xml/default_stat_file" -v @ymin rules.xml)
Y_MAX=$($XML sel -t -m "/xml/default_stat_file" -v @ymax rules.xml)
X_MAX=$($XML sel -t -m "/xml/default_stat_file" -v @xmax rules.xml)
PLOT_ARGS="--persist --no-gui -q"
plot=0

if [ "$Y_MIN" == "" ] ; then
	Y_MIN=0
fi
if [ "$Y_MAX" == "" ] ; then
	Y_MAX=500
fi
if [ "$X_MAX" == "" ] ; then
	X_MAX=0
fi


if [ ! -e rules.out ] ; then
	echo "Please run parsing_rules first"
	exit 1
fi

echoerr() { echo "$@" 1>&2; }

function read_input_until {
	init=""
	declare -a list=("${!1}")
	while [ 1 ] ; do
		read -s -n 1 init
		
		if [[ ${list[@]} =~ $init || $init == "" ]] ; then
			break
		fi
	done

	if [[ $init == ""  ]] ; then
		init=${list[0]}
	fi
	echo $init
}

function ask_save_best(){
	echoerr "Save best ? (0 : no/1 : yes/2 : moving max)"
	arg=(0 1 2)
	read_input_until arg[@]
}

function ask_dimension(){
	echoerr "Which dimension ? (0-9)"
	arg=$(seq 0 9)
	read_input_until arg[@]
}

function ask_higher_better(){
	echoerr "Is higher value better on this dimension ? (0/1)"
	arg=(0 1)
	read_input_until arg[@]
}

function handler(){
	exit 0
}

repeat=1
#trap handler SIGINT
#cause problems when trap on read

echo "Want do you want to do ?"
echo " -- single parameter - mean over all (s) [default]" 
echo " -- multiple parameters - mean over one (m)"
echo " -- plot one parameter from id (o)"
echo " -- analyse implication of one parameter (a)"

arg=("s" "m" "o" "a")
multiple=`read_input_until arg[@]`

if [[ $multiple == "m" ]] ; then
	echo "Want to plot ? (0/1)"
	arg=(0 1)
	plot=`read_input_until arg[@]`

	dimension=`ask_dimension`
	
	save_best=`ask_save_best`

	higher_better=`ask_higher_better`

	COMMAND="best_param.m $STAT_FILE $plot $dimension $save_best $higher_better $Y_MIN $Y_MAX $X_MAX"
elif [[ $multiple == "s" ]] ; then
	echo "Want do you want to do? only one dimension (s) / plot all dimension (a) : [s]"
	arg=("s" "a")
	multiple=`read_input_until arg[@]`
	plot=1

	if [[ $multiple == "s" ]] ; then		
		dimension=`ask_dimension`

		save_best=`ask_save_best`

		higher_better=`ask_higher_better`

		COMMAND="one_by_one.m $STAT_FILE $dimension $save_best $higher_better $Y_MIN $Y_MAX $X_MAX"
	else
		save_best=`ask_save_best`

		higher_better=`ask_higher_better`

		COMMAND="one_by_one.m $STAT_FILE $save_best $higher_better $Y_MIN $Y_MAX $X_MAX"
	fi
elif [[ $multiple == "o" ]] ; then
	dimension=`ask_dimension`
	save_best=`ask_save_best`
	if [ $save_best -ge 1 ] ; then
		higher_better=`ask_higher_better`
	else
		higher_better=1
	fi

	plot=1
	echo "Give id number ?"
	read -s id
	COMMAND="best_param_plot.m $STAT_FILE $plot $dimension $save_best $higher_better $id $Y_MIN $Y_MAX $X_MAX"
	repeat=2
elif [[ $multiple == "a" ]] ; then
	dimension=`ask_dimension`
	save_best=`ask_save_best`
	if [ $save_best -ge 1 ] ; then
		higher_better=`ask_higher_better`
	else
		higher_better=1
	fi

	echo "Give parameter name ?"
	read name
	COMMAND_BASE="analyse_param.m $STAT_FILE $dimension $save_best $higher_better"
	repeat=2
fi


while [ $repeat -ge 1 ] ; do
	
	directories=`cat rules.out`
	for dir in $directories ; do
		
		if [[ $multiple == "a" ]] ; then
			val=`$XML sel -t -m "/xml/fold[@name='$dir']/param[@name='$name']" -v @values -n rules.xml`
			mm=`$XML sel -t -m "/xml/fold[@name='$dir']/param" -v @values -n rules.xml | wc -l`
			mm=`expr $mm - 1`
			rank=`$XML sel -t -m "/xml/fold[@name='$dir']/param" -v @name -n rules.xml | grep -n $name | sed -e 's/:.*//'`
			COMMAND="$COMMAND_BASE $name $val $mm $rank $Y_MIN $Y_MAX $X_MAX"
		fi

		echo "############################ $dir #####################################"

		tmp1=`mktemp`
		#review sort
		#head -n 1 $dir/rules.out > $tmp1
		#cat $dir/rules.out | sed '1d' | grep -v '^$' | sort -n >> $tmp1
		#mv $tmp1 $dir/rules.out
	
		cd $dir
		if [ $plot -eq 0 ] ; then
			PLOT_ARGS=""
		fi
		echo "OCTAVE_PATH=$LHPO_PATH/utils octave $PLOT_ARGS $LHPO_PATH/utils/$COMMAND"
		OCTAVE_PATH=$LHPO_PATH/utils octave $PLOT_ARGS $LHPO_PATH/utils/$COMMAND
		cd ..
	done
	
	if [[ $repeat -eq 2 && $multiple == "o" ]] ; then
		echo "Give id number ?"
		read -s id
		COMMAND="best_param_plot.m $STAT_FILE $plot $dimension $save_best $higher_better $id $Y_MIN $Y_MAX $X_MAX"
	elif [[ $repeat -eq 2 && $multiple == "a" ]] ; then
		echo "Give parameter name ?"
		read name
	else 
		repeat=0
	fi

done

