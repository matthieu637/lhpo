#!/usr/bin/octave -qf
arg_list = argv ();
file_to_load=arg_list{1};
plotme=str2num(arg_list{2});
column=str2num(arg_list{3});
save_best=str2num(arg_list{4});

fid = fopen ("rules.out");
line = fgetl (fid); %ignore first line

line = fgetl (fid);
lastkey='';
i=1;
printf('\t \t \t -> max median \t median median \t mean median \n');
clear result;
while line != -1
  key = substr(line, 1, rindex(line, '_'));
  if( !strcmp(key, lastkey))
    X=load_dirs(key, file_to_load, column, save_best);
    printf('%s (%d) \t -> %f \t %f \t %f\n', key,i, max(median(X)), median(median(X)), mean(median(X)));
    fflush(stdout);
    result(end+1,:)=[i max(median(X))];
    i = i +1;
    
    if plotme==1
      figure
      s=plotMedianQ(X, 'r');
      title(key);
    endif
    
  endif
  lastkey=key;
  line = fgetl (fid);  
endwhile

if plotme
	input("press a key") 
endif
