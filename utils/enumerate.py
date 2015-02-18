#!/usr/bin/python

import fileinput

def listeproduit(L):
	if len(L)==0: # produit vide
		return [[]]
	else:
		K=listeproduit(L[1:]) #appel récursif 
		return [[x]+y for x in L[0] for y in K] #ajouter tous les éléments du premier ensemble au produit cartésien des autres

tab=[];
for line in fileinput.input():
	tab.append(line.replace('\n','').split(','))

for line in listeproduit(tab):
	print(line)
