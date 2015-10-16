#!/usr/bin/python3
# -*- coding: utf-8 -*-

import fileinput
import sys
from IPython.core.debugger import Tracer

#called from exec
def str2bool(v):
  return v.lower() in ("yes", "true", "1")

#get data from stdin
dico={}
headers=[]
firstline=True
for line in sys.stdin.readlines():
	#sys.stderr.write(line);
	if firstline:
		for val in line.replace('\n','').split(' '):
			dico[val]=[]
			headers.append(val)
		firstline=False
	else:
		i=0;
		for val in line.replace('\n','').split('_'):
			dico[headers[i]].append(val)
			i=i+1;

#apply rules
for rule in open(sys.argv[1]).readlines():
	i=0; #while forced because of dynamic removing
	while i < len(dico[headers[0]]):
#		Tracer()()
		exec(rule)
		if (not test):
			for header in headers:
				del dico[header][i]
		else:
			i=i+1;

#display data
print(headers)
for i in range(0, len(dico[headers[0]])):
	for h in headers:
		print(dico[h][i], end="_")
	print()

