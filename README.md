# lhpo
Lightweight HyperParameter Optimizer (gridsearch)

Run experiments with different parameters, to average, ...
### Dependencies :
- python3
- xmlstarlet
- python3-joblib
- octave (optional for statistics/graphs)
```
#for Ubuntu to have acces to xml as on ArchLinux
sudo ln -s /usr/bin/xmlstartlet /usr/local/bin/xml
#or add this line to your .bashrc
alias xml='/usr/bin/xmlstarlet'
```

### Usage :
Create a rules.xml file in a dir and run
```bash
$ ./parsing_rules.bash dir/
```

This will generate different folds in dir.

Now you can call 
```bash
$ ./optimizer.bash dir/
```
from every node that can participate.

If you want to monitor the progress :
```bash
$ ./count.bash dir/
```

If you want to remove all fold in the dir (be careful you'll lost your previous generated data):
```bash
$ ./clear.bash dir/
```

### How to use with a computer cluster
- [Grid5000](https://www.grid5000.fr/)
- [Amazon Web Services](https://github.com/matthieu637/lhpo/tree/master/aws) setup

lhpo relies on synchronization by NFS. There is no need to allocate a specific number of resources.

Example with 3 agents controlloing the whole process :
- [grid.booker] a script checks that there is work remaining (with ./count.bash \<dir\>), monitor which nodes are free, then makes a reservation
- [grid.cleaner] a script checks that each running work has indeed an online node (they might be
killed before having the time to remove the allocation), if not the work is tagged to-be-done again (with ./count.bash \<dir\> --remove-dead-node)
- [grid.balancer] a script monitors the CPU used by each reserved node, if it remains a free ”slot” it tells
the node to run another experiment in parallel (because some algorithms can be parallelized on several threads and
others not)

Scripts for those behaviors are given is aws/grid5000 directories.

### Example (performing a gridsearch to optimize hyperparameters):

run.py
```python
import configparser
import time
 
#the main script read hyperparameters through config.ini
config = configparser.ConfigParser()
config.read('config.ini')
algo=config['agent']['algo']
alpha=float(config['agent']['alpha'])
noise=float(config['agent']['noise'])
start_time = time.time()
 
#YOUR MAIN ALGO
#...
 
#end of script - inform that the script finished
with open('time_elapsed', 'w') as f:
  f.write('%d' % int((time.time() - start_time)/60))
#you probably also want to write some file with the result
```

Get the hyper-optimization tool on your frontend.
```bash
cd YOUR_LHPO_PATH
git clone https://github.com/matthieu637/lhpo.git
```

Prepare experiment directory
```bash
cd
mkdir -p exp/continuous_bandit_perfect_critic
cd exp/continuous_bandit_perfect_critic
#set up the file to describe your hyper parameters 
vim rules.xml
```

```xml
<xml>
        <command value='/home/nfs/mzimmer/python_test/run.py' />
        <args value='' />
 
        <!-- my script is already multi-threaded -->
        <max_cpu value='1' />
 
        <ini_file value='config.ini' />
        <end_file value='time_elapsed' />
 
        <fold name='learning_speed' >
               <param name='algo' values='SPG,DPG' />
               <param name='alpha' values='0.01,0.001,0.0001' />
               <param name='noise' values='0.01,0.001,0.0001' />
        </fold>
 
</xml>
```

```bash
#set up the config file (these values will be changed automatically) 
vim config.ini
```

```ini
[agent]
algo=SPG
noise=0.01
alpha=0.0001
```
Generate the possible hyperparameters combinations with :
```bash
cd YOUR_LHPO_PATH
./parsing_rules.bash ~/exp/continuous_bandit_perfect_critic
#check how many exp will be performed
./count.bash ~/exp/continuous_bandit_perfect_critic
#-> running : 0
#-> to do : 18
#-> done : 0
```

Now you can launch experiments (in this example, we use OAR with 2 jobs to perform the 18 exp).
```bash
oarsub -lhost=1/thread=5,walltime=30:00:00 "cdl ; ./optimizer.bash ~/exp/continuous_bandit_perfect_critic"
oarsub -lhost=1/thread=10,walltime=30:00:00 "cdl ; ./optimizer.bash ~/exp/continuous_bandit_perfect_critic"
 
#note that my bashrc contains those two lines : 
shopt -s expand_aliases
alias cdl='cd YOUR_LHPO_PATH'
```
If you don't use OAR but at least NFS to share the "~/exp/continuous_bandit_perfect_critic".
You must dispatch the optimizer.bash command by hand on each computer or through ssh:
```bash
cd YOUR_LHPO_PATH ;  ./optimizer.bash ~/exp/continuous_bandit_perfect_critic
```
If you don't even use NFS, then you can only use the optimizer.bash on one computer.

After that you can monitor the progress with
```bash
cd YOUR_LHPO_PATH
./count.bash ~/exp/continuous_bandit_perfect_critic/
#-> running : 2
#-> to do : 16
#-> done : 0
```

Once its finished, the results looks like :
```bash
#move to exp dir
cd ~/exp/continuous_bandit_perfect_critic
#move to fold
cd learning_speed
ls
#this contains all the dir with all setup of the fold
#DAC_0.1_0.1  rules.out  SAC_0.001_0.01  SAC_0.01_0.001 ...
ls -l DAC_0.1_0.1
#-> config.ini : the config.ini for this experiment
#-> executable.trace : executable used with which args
#-> full.trace : everything your executable output to stderr and stdout
#-> host : which computer performed the experiment
#-> host_tmp : in which tmp dir (to reduce NFS read/write)
#-> perf.data : data written by script
#-> testing.data : data written by script
#-> time_elapsed : number of min to perform this exp
```

### Example of scripts
If you want to optimize python executable, you might need to specify first a bash script as "command" in rules.xml in order to activate the python virtual environmnent, etc.

For [DDRL](https://github.com/matthieu637/ddrl):
```bash
#!/bin/bash

#define some environment variable
export LANG=en_US.UTF-8
export OMP_NUM_THREADS=1
export MUJOCO_PY_MJKEY_PATH=~/.mujoco/$(hostname)/mjkey.txt

#activate virtual env
. /home/nfs/mzimmer/git/aaal/scripts/activate.bash
#run executable
python -O /home/nfs/mzimmer/git/ddrl/gym/run.py --goal-based

exit $?
```

For [OpenAI baselines](https://github.com/openai/baselines):
```bash
#!/bin/bash

export OMP_NUM_THREADS=1

#activate virtual env
. /home/nfs/mzimmer/git/aaal/scripts/activate.bash

#convert config.ini to command line args and call baselines
OPENAI_LOGDIR=. OPENAI_LOG_FORMAT=csv python -O -m baselines.run $(cat config.ini | grep '=' | sed 's/^/--/' | sed 's/$/ /' | xargs echo)
#store status
r=$?

#for lhpo compatibility
echo '0' > time_elapsed

exit $r
```

For [Augmented Random Search](https://github.com/modestyachts/ARS):
```bash
#!/bin/bash

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export GOTO_NUM_THREADS=1
export RCALL_NUM_CPU=1

min_number() {
    printf "%s\n" "$@" | sort -g | head -n1
}

. /home/mzimmer/git/aaal/scripts/activate.bash
PORT=$RANDOM
WORKER=$(min_number $(cat config.ini | grep 'n_directions' | cut -d'=' -f2) $(cat /proc/cpuinfo | grep processor | wc -l))
RAYDIR=$(ray start --head --redis-port=$PORT --num-cpus=$WORKER |& grep '/tmp/ray/session' | head -1 | sed 's|.* /tmp|/tmp|' | sed 's|/logs.*||')

python -O /home/mzimmer/git/aaal/build/ARS/code/ars.py --port $PORT --seed $RANDOM --dir_path . --n_workers $WORKER $(cat config.ini | grep '=' | grep -v run | sed 's/^/--/' | sed 's/$/ /' | xargs echo) 
r=$?
echo '0' > time_elapsed

if [ $r -ne 0 ] ; then
    exit $r
fi

cat log.txt | cut -f4 | grep -v 'timesteps' > x.learning.data
echo "# { \"t_start\": 1550549468.1440182, \"env_id\": \"$(cat config.ini | grep env | cut -d '=' -f2)\"}" > 0.1.monitor.csv
cat log.txt | cut -f1,2,3 | sed -e 's/[	]/,/g' >> 0.1.monitor.csv
rm log.txt

#stop ray for specific port
kill $(cat $RAYDIR/logs/redis.out | grep pid | sed -e 's/^.*pid=\([0-9]*\),.*$/\1/')
kill $(cat $RAYDIR/logs/redis-shard_0.out | grep pid | sed -e 's/^.*pid=\([0-9]*\),.*$/\1/')
kill $(lsof -t $RAYDIR/sockets/plasma_store)
rm -rf $RAYDIR

exit 0
```
