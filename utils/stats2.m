#!/usr/bin/octave -qf

arg_list = argv();
file = arg_list{1};

X=load_dirs(file);

if nargin == 1
	column = 1:size(X,2);
else
	column = arg_list{2};
endif


for i=column
	figure

	plot(X(:,i))
	title(num2str(i))
endfor

input("press a key")

