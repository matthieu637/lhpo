#!/usr/bin/octave -qf

arg_list = argv ();
file_to_load=arg_list{1};
plotme=str2num(arg_list{2});
column=str2num(arg_list{3});
save_best=str2num(arg_list{4});
higher_better=str2num(arg_list{5});
id=str2num(arg_list{6});
ymin=str2num(arg_list{7});
ymax=str2num(arg_list{8});

%plotme=2;

fid = fopen ("rules.out");
line = fgetl (fid); %ignore first line

line = fgetl (fid);
lastkey='';
i=1;
printf('\t \t \t \t -> max median \t (ind) max median \t median median \t mean median \t mean low quartile \t mean over 10 last percent \t nb sample \n');
clear result;
while line != -1
  try
    key = substr(line, 1, rindex(line, '_'));
    if( !strcmp(key, lastkey) )
    	if( i == id )
	      X=load_dirs(key, file_to_load, column, save_best, higher_better);
	      if(size(X,1) == 1)
	      	X=[X;X;X];
	      endif
	      Xsub = X(:, (end - floor(size(X,2)*0.02)):end);
	      size(X)
	      S=statistics(X);
              if higher_better
%             [uu,vv]= max(S(3,:));
                  [uu,vv]= max(S(2,:));
              else
%             [uu,vv]= max(S(3,:));
                  [uu,vv]= min(S(4,:));
              endif
	      yy = median(S(3,:));
	      ww = mean(S(3,:));
	      zz = mean(S(2,:));
	      rr = median(median(Xsub));
	      printf('%s (%d) \t \t -> %f\t %f \t %f \t %f \t %f \t %f \t %f \n', key,i, uu, vv, yy, ww, zz, rr, size(X,1) );
	      fflush(stdout);
      
	      if plotme==1
	        figure
	        s=plotMedianQ(X, 'r');
                ylim([ymin ymax])
	        title(key);
              elseif plotme==2
                figure
                Y=load_dirs(key, file_to_load, 6, 0, 0);
                plot(statistics(cumsum (Y, 2))(3,:), statistics(X)(3,:));
                ylim([ymin ymax])
                title(key);
      	      endif
      	      break
	endif
    	i = i +1;
    endif
    lastkey=key;
  catch
	printf('error %s\n', lasterror.message);
	key = substr(line, 1, rindex(line, '_'));
	lastkey='';
	i = i+1;
  end_try_catch

    line = fgetl (fid);  
endwhile

%begin messy prefer --persist --no-gui -q
%input("press a key");
function q()
	exit
endfunction
printf("press q to quit\n")



