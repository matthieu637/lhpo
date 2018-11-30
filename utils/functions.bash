#!/bin/bash

function cdIntoFirstArg(){

if [ $# -lt 1 ] ; then
        echo "Usage : $0 <dir>"
        echo "  <dir> containing a rules.xml"
        exit 1
fi

if [ ! -d $1 ] ; then
        echo "$1 is not a valid directory"
        exit 1
fi

export LHPO_PATH=$(pwd)
cd $1

}

function nbcpu(){
	cat /proc/cpuinfo | grep processor | wc -l
}

if [ -e /etc/debian_version ] ; then
	XML=/usr/bin/xmlstarlet
else
	XML=xml
fi

