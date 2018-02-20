#!/usr/bin/octave -qf

arg_list = argv ();
if length(arg_list) == 4+3
	X=load_dirs('', arg_list{1}, str2num(arg_list{2}), str2num(arg_list{3}), str2num(arg_list{4}));
	s=plotMedianQ(X, 'r');
	[uu,vv]= max(median(X));
	printf('\t -> %f\t %f \t %f \t %f \t %f\n', uu, vv, median(median(X)), mean(median(X)), mean(statistics(X)(2,:)));
	fflush(stdout);
elseif length(arg_list) == 5+3
	X=load_dirs('.', strcat('[0-9.]*', arg_list{1}), str2num(arg_list{2}), str2num(arg_list{3}), str2num(arg_list{4}));
	if(size(X,1) == 1)
		plot(X, '.');
		[uu,vv]= max(X);
		printf('\t -> %f\t %f \t %f \t %f \t %f\n', uu, vv, median(X), mean(X), min(X));
	else
		s=plotMedianQ(X, 'r');
		[uu,vv]= max(median(X));
		printf('\t -> %f\t %f \t %f \t %f \t %f\n', uu, vv, median(median(X)), mean(median(X)), mean(statistics(X)(2,:)));
	endif
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

function q() 
        exit
endfunction
printf("press q to quit\n")

