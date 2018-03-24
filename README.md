# lhpo
Lightweight HyperParameter Optimizer (gridsearch)

Run experiments with different parameters, to average, ...
##### Dependencies :
- python3
- xmlstarlet
- python3-joblib
- octave (optional for statistics/graphs)
```
#for Ubuntu to have acces to xml as on ArchLinux
sudo ln -s /usr/bin/xmlstartlet /usr/local/bin/xml
```

##### Example :
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

##### How to use with a computer cluster
- [Grid5000](https://www.grid5000.fr/)
- [Amazon Web Services](https://github.com/matthieu637/lhpo/tree/master/aws)

lhpo relies on synchronization by NFS. There is no need to allocate a specific number of resources.

Example with 3 agents controlloing the whole process :
- [booker] a script checks that there is work remaining (with ./count.bash <dir>), monitor which nodes are free, then makes a reservation
- [cleaner] a script checks that each running work has indeed an online node (they might be
killed before having the time to remove the allocation), if not the work is tagged to-be-done again (with ./count.bash <dir> --remove-dead-node)
- [optimizer] a script monitors the CPU used by each reserved node, if it remains a free ”slot” it tells
the node to run another experiment in parallel (because some algorithms can be parallelized on several threads and
others not)


