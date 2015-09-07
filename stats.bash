#!/bin/bash

. ./utils/functions.bash
cdIntoFirstArg $@

STAT_FILE=$(xml sel -t -m "/xml/default_stat_file" -v @value rules.xml)

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
	echoerr "Save best ? (0/1)"
	arg=(0 1)
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

echo "Want do you want to do ?"
echo " -- single parameter - mean over all (s) [default]" 
echo " -- multiple parameters - mean over one (m)"
echo " -- plot one parameter from id (o)"

arg=("s" "m" "o")
multiple=`read_input_until arg[@]`

if [[ $multiple == "m" ]] ; then
	echo "Want to plot ? (0/1)"
	arg=(0 1)
	plot=`read_input_until arg[@]`

	dimension=`ask_dimension`
	
	save_best=`ask_save_best`

	higher_better=`ask_higher_better`

	COMMAND="best_param.m $STAT_FILE $plot $dimension $save_best $higher_better"
	#COMMAND="stats.m $STAT_FILE"
elif [[ $multiple == "s" ]] ; then
	echo "Want do you want to do? only one dimension (s) / plot all dimension (a) : [s]"
	arg=("s" "a")
	multiple=`read_input_until arg[@]`

	if [[ $multiple == "s" ]] ; then		
		dimension=`ask_dimension`

		save_best=`ask_save_best`

		COMMAND="one_by_one.m $STAT_FILE $dimension $save_best"
	else
		save_best=`ask_save_best`

		COMMAND="one_by_one.m $STAT_FILE $save_best"
	fi
elif [[ $multiple == "o" ]] ; then
	dimension=`ask_dimension`
	save_best=`ask_save_best`
	higher_better=`ask_higher_better`
	plot=1
	echo "Give id number ?"
	read -s id
	COMMAND="best_param_plot.m $STAT_FILE $plot $dimension $save_best $higher_better $id"
fi

directories=`cat rules.out`
for dir in $directories ; do
	echo "############################ $dir #####################################"

	cd $dir
	echo "OCTAVE_PATH=$LHPO_PATH/utils octave $LHPO_PATH/utils/$COMMAND"
	OCTAVE_PATH=$LHPO_PATH/utils octave $LHPO_PATH/utils/$COMMAND
	cd ..
done

