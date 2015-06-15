#!/bin/bash

function cdIntoFirstArg(){

if [ ! $# -eq 1 ] ; then
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
