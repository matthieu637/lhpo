#!/usr/bin/python3
# -*- coding: utf-8 -*-

import fileinput
import sys

def is_int(s):
    try:
        int(s)
        return True
    except ValueError:
        return False

def listeproduit(L):
	if len(L)==0: # produit vide
		return [[]]
	else:
		K=listeproduit(L[1:]) #appel recursif 
		return [[x]+y for x in L[0] for y in K] #ajouter tous les éléments du premier ensemble au produit cartésien des autres

tab=[];
for line in fileinput.input():
#	sys.stderr.write(line); 
	rline = line.replace('\n','');
	if rline.count(',') != 0:
		tab.append(rline.split(','))
	elif rline.count(':') == 1 and is_int(rline.split(':')[0]) and is_int(rline.split(':')[1]) and int(rline.split(':')[0]) < int(rline.split(':')[1]):
		begin=rline.split(':')[0]
		end=rline.split(':')[1]
		tab.append([i for i in range(int(begin),int(end))])
	else: 
		tab.append([rline])

for line in listeproduit(tab):
	print(line)
