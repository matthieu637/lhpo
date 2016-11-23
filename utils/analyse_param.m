#!/usr/bin/octave -qf

arg_list = argv ();
file_to_load=arg_list{1};
column=str2num(arg_list{2});
save_best=str2num(arg_list{3});
higher_better=str2num(arg_list{4});

key=arg_list{5};
vals=arg_list{6};
mmax=str2num(arg_list{7});
rank=str2num(arg_list{8});

printf('\t \t \t \t -> max median \t (ind) max median \t median median \t mean median \t mean low quartile \t mean over 10 last percent \n');

if strfind(vals, ':') >= 0
       mmin_=str2num(strsplit(vals,':')(1){1});
       mmax_=str2num(strsplit(vals,':')(2){1});
       vals='';
       for i=mmin_:mmax_
               vals=strcat(vals, num2str(i), ',');
       endfor
endif

if strcmp(key, 'run')
       mmax=mmax+1
endif

for val=strsplit(vals, ',')
	clear base
	base_regx='[a-zA-Z0-9]*';
	if rank == 1
		base=val;
	else
		base=base_regx;
	endif
	
	for i=2:mmax
		if i == rank
			base=strcat(base, '_', val);	
		else
%			if i == 3
%				base=strcat(base, '_', 'false');
%			elseif i == 4
%				base=strcat(base, '_', 'true');
%			elseif i == 5
%				base=strcat(base, '_', 'true');
%			elseif i == 6
%				base=strcat(base, '_', 'false');
%			elseif i == 7
%				base=strcat(base, '_', 'true');
%			elseif i == 8
%				base=strcat(base, '_', 'true');
%			elseif i == 9
%				base=strcat(base, '_', 'false');
%			elseif i == 10
%				base=strcat(base, '_', 'true');
%			else
				base=strcat(base, '_', base_regx);	
%			endif
		endif
	endfor

	if ! strcmp(key, 'run')
		base=strcat(base, '_');
	endif

	printf('X=load_dirs(%s, %s, %d, %d, %d);\n', base{1,1}, file_to_load, column, save_best, higher_better);
	try
		X=load_dirs(base{1,1}, file_to_load, column, save_best, higher_better);
		Xsub = X(:, (end - floor(size(X,2)/10)):end);
		S=statistics(X);
		if higher_better
	              [uu,vv]= max(S(2,:));
		else
	              [uu,vv]= min(S(4,:));
		endif
		yy = median(S(3,:));
	      	ww = mean(S(3,:));
		zz = mean(S(2,:));
		rr = mean(mean(Xsub));
		printf('(%s : %s) \t \t -> %f\t %f \t %f \t %f \t %f \t %f \n', key, val{1,1}, uu, vv, yy, ww, zz, rr);
		fflush(stdout);
	
	        figure
	        s=plotMedianQ(X, 'r');
	        title(strcat(key, ' : ', val));
	catch
		continue
	end_try_catch
endfor

input("press a key");

