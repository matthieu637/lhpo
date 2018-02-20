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
%to find very max uncoment next line
mmax=rank

ymin=str2num(arg_list{9});
ymax=str2num(arg_list{10});

printf('\t \t \t \t -> max median \t (ind) max median \t median median \t mean median \t mean low quartile \t mean over 10 last percent \t nb sample \n');

if strfind(vals, ":") > 0 && mmax == 0 
	new_vals=""
	for i=str2num(strsplit(vals, ":"){1}):str2num(strsplit(vals, ":"){2});
		new_vals=strcat(new_vals, num2str(i), ',');
	endfor
	vals=new_vals;
endif

for val=strsplit(vals, ',')
	clear base
	base_regx='[-.a-zA-Z0-9]*';
	if rank == 1
		base=val;
	else
		base=base_regx;
	endif
	
	for i=2:mmax
		if i == rank
			base=strcat(base, '_', val);	
		else
			if i == 200
				base=strcat(base, '_', '(1[12]||[23])');
			elseif i == 400
				base=strcat(base, '_', 'false');
			elseif i == 1 %never 1
				base=strcat(base, '_', '1');
			elseif i == 200
				base=strcat(base, '_', '(2||11||12)');
			elseif i == 700
				base=strcat(base, '_', 'false');
			elseif i == 400
				base=strcat(base, '_', '0:0:0:0:10000:10000');
			elseif i == 300
				base=strcat(base, '_', '7');
			else
				base=strcat(base, '_', base_regx);	
			endif
		endif
	endfor

	if strcmp('run', key) == 0
		base=strcat(base, '_');
	else
		base=strcat(base, '/');
	endif

	printf('X=load_dirs(%s, %s, %d, %d, %d);\n', base{1,1}, file_to_load, column, save_best, higher_better);
	try
		X=load_dirs(base{1,1}, file_to_load, column, save_best, higher_better);
		if(size(X,1)==0)
			printf('error path? no data\n')
			continue;
		endif
		Xsub = X(:, (end - floor(size(X,2)*0.02)):end);
		if size(X,1) == 1
			X=[X;X;X];
		endif
		S=statistics(X);
		if higher_better
	              [uu,vv]= max(S(2,:));
		else
	              [uu,vv]= min(S(4,:));
		endif
		yy = median(S(3,:));
	      	ww = mean(S(3,:));
		zz = mean(S(2,:));
		rr = median(median(Xsub));
		printf('(%s : %s) \t \t -> %f\t %f \t %f \t %f \t %f \t %f \t %f \t %f \n', key, val{1,1}, uu, vv, yy, ww, zz, rr, size(X,1), size(X,2) );
		fflush(stdout);
	
		s2=strcat(key, '-',val, '.png'){1,1};
		%if exist(s2) != 0
		%	continue
		%endif
if false
	        h=figure;
	        s=plotMedianQ(X, 'r');
	        title(strcat(key, ' : ', val));
		axis([0 length(X) ymin ymax]);
		xlabel('epsiode')
		ylabel('v\_error')

		WW = 5; HH = 4;     
		set(h,'PaperUnits','inches')                                                                                                         
		set(h,'PaperOrientation','portrait');                                                                                                
		set(h,'PaperSize',[HH,WW])    
		set(h,'PaperPosition',[0,0,WW,HH])    
		     
		FN = findall(h,'-property','FontName');     
		set(FN,'FontName','/usr/share/fonts/TTF/DejaVuSerifCondensed.ttf');     
		FS = findall(h,'-property','FontSize');
		set(FS,'FontSize',11);

		if exist(s2) == 0
			sleep(1)
			print(h , s2, '-r175')
			sleep(1)
		endif
endif
	catch
		lasterror ()
		continue
	end_try_catch
endfor

input("press a key");

