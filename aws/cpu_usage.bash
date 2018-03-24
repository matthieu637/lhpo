#!/bin/bash

#CORECOUNT=$(grep cpu /proc/stat | grep -v 'cpu ' | wc -l)
#echo $CORECOUNT cores not needed for calculation though

DELAY=${1:-1}

function getstat() {
    grep 'cpu ' /proc/stat | sed -e 's/  */x/g' -e 's/^cpux//'
}

function extract() {
    echo $1 | cut -d 'x' -f $2
}

function change() {
    local e=$(extract $ENDSTAT $1)
    local b=$(extract $STARTSTAT $1)
    local diff=$(( $e - $b ))
    echo $diff
}

#Record the start statistics

STARTSTAT=$(getstat)

sleep $DELAY

#Record the end statistics

ENDSTAT=$(getstat)


#http://www.mjmwired.net/kernel/Documentation/filesystems/proc.txt#1236
#echo "From $STARTSTAT"
#echo "TO   $ENDSTAT"
#     usr    nice   sys     idle       iowait irq    guest
#From 177834 168085 1276260 3584351494 144468 154895 0 0 0 0
#TO   177834 168085 1276261 3584351895 144468 154895 0 0 0 0

USR=$(change 1)
SYS=$(change 3)
IDLE=$(change 4)
IOW=$(change 5)

#echo USR $USR SYS $SYS IDLE $IDLE IOW $IOW

ACTIVE=$(( $USR + $SYS + $IOW ))
TOTAL=$(($ACTIVE + $IDLE))
PCT=$(( $ACTIVE * 100 / $TOTAL ))

#echo "BUSY $ACTIVE TOTAL $TOTAL $PCT %"
echo "$PCT"
