#!/usr/bin/python3
# -*- coding: utf-8 -*-

import fileinput
import sys
from joblib import Parallel, delayed
import multiprocessing
import copy

#called from exec
def str2bool(v):
  return v.lower() in ("yes", "true", "1")

def processInput(a, b, _rules, headers):
	#prepare dico
	dico={}
	for header in headers:
		dico[header]=[];

	#partial load file
	j=0
	file_=open(sys.argv[2], 'r')
	file_.readline()
	for line in file_.readlines():
		i=0;
		if j not in range(a,b):
			j=j+1
			continue
		for val in line.replace('\n','').split('_'):
			dico[headers[i]].append(val)
			i=i+1
		j=j+1

	#test rule over subpart of the file
	result=[]
	for j in range(a,b):
		i=j-a
		test=True
		for rule in _rules:
			test=eval(rule)
			if test==False:
				break
		result.append((test,j))
	return result

#read headers on the first line
headers=[]
for line in open(sys.argv[2]).readlines():
	for val in line.replace('\n','').split(' '):
		headers.append(val)
	break;


num_cores = multiprocessing.cpu_count()
#num_cores = 1

#read rules from file
rules=[]
for rule in open(sys.argv[1]).readlines():
	rules.append(rule)
#	print(rule)

#prepare to dispatch
n=int(sys.argv[3])-1
start=[i for i in range(0,n,int(n/num_cores + 1))]
start2 = copy.deepcopy(start)
start2.remove(0)
start2.append(n)
pool=[]
for i in range(len(start)):
	if i < len(start2):
		pool.append((start[i], start2[i]))
	else:
		pool.append((start[i], n))

results=Parallel(n_jobs=num_cores)(delayed(processInput)(i, j, rules, headers) for (i,j) in pool )

rr=[]
for r in results:
	for (i,j) in r:
		rr.append(i)

#print(results)
#print(rr)

#display data
print(headers)

file_=open(sys.argv[2], 'r')
file_.readline()
j=0
for line in file_.readlines():
	i=0;
	if j >= n:
		sys.stderr.write('warning n is too low')
		break
	if rr[j]:
		print(line.replace('\n',''))
	j=j+1
print()

