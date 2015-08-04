#!/usr/bin/octave -qf
%graphics_toolkit('gnuplot')
clear all
close all

arg_list = argv ();
if length(arg_list) == 3
	X=load_dirs('', arg_list{1}, str2num(arg_list{2}), str2num(arg_list{3}));
	s=plotMedianQ(X, 'r');
	[uu,vv]= max(median(X));
	printf('\t -> %f\t %f \t %f \t %f \t %f\n', uu, vv, median(median(X)), mean(median(X)), mean(statistics(X)(2,:)));
	fflush(stdout);
else
	for i=1:10
		try
			X=load_dirs('', arg_list{1}, i, str2num(arg_list{2}));
			figure;
			s=plotMedianQ(X, 'r');
			title(num2str(i));
		catch
			break
		end_try_catch
	endfor
endif

input("press a key");


