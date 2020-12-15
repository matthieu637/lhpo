#!/bin/bash

totmem=$(nvidia-smi --query-gpu=memory.total --format=csv | tail -n 1 | cut -d' ' -f1)
threads=$(cat /sys/fs/cgroup/cpuset/$(< /proc/self/cpuset)/cpuset.cpus |  python3 -c "import sys; I=sys.stdin.readline();print(sum([ 1 + int(l.split('-')[1]) - int(l.split('-')[0]) if '-' in l else 1 for l in (I[:-1]).split(',')]))" )

P=$@

echo "max threads $threads"
echo "command I'll run: $P"

counter=1
echo "launching more jobs... ($counter)"
$P &
pid=$!
allpid=$pid
previous_mem=0
all_mem=""
sleep 20s

while [ 1 ] ; do

    if [ $counter -eq $threads ] ; then
        echo "stop cause of thread"
        break
    fi

    mem=$(nvidia-smi --query-gpu=memory.used --format=csv | tail -n 1 | cut -d' ' -f1)
    mem=$(echo "(100 * $mem ) / $totmem" | bc)
    gpu=$(nvidia-smi --query-gpu=utilization.gpu --format=csv | tail -n 1 | cut -d' ' -f1)

    memdiff=$(expr $mem - $previous_mem)
    previous_mem=$mem
    all_mem="$all_mem $memdiff"
    mem_ratio=$(echo $all_mem | sed -e 's/ /\n/g' | sort -n | tail -n 1)
    
    predicted_mem=$(echo "$mem_ratio * ($counter + 1)" | bc)
    if [ $predicted_mem -ge 90 ] ; then
        echo "stop cause of mem"
        break
    fi
    
    predicted_gpu=$(echo "($gpu * ( $counter + 1)) / $counter" | bc)
    if [ $predicted_gpu -ge 95 ] ; then
        echo "stop cause of gpu util."
        break
    fi
    counter=$(expr $counter + 1)
    echo "launching more jobs... ($counter)"

    $P &
    pid=$!
    allpid="$allpid $pid"
    sleep 25s
done

wait $allpid


