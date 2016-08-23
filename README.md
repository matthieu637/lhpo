# lhpo
Lightweight HyperParameter Optimizer

Run experiments with different parameters, to average, ...
##### Dependencies :
- python
- xmlstarlet
- ipython3
- octave (optional for statistics/graphs)

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
