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
printf('\t \t \t \t -> max median \t (ind) max median \t median median \t mean median \t mean low quartile \t mean over 10 last percent \n');
clear result;
while line != -1
  try
    key = substr(line, 1, rindex(line, '_'));
    if( !strcmp(key, lastkey))
      X=load_dirs(key, file_to_load, column, save_best);
      Xsub = X(:, 1:end - floor(size(X,2)/10));
      S=statistics(X);
      [uu,vv]= max(S(3,:));
      yy = median(S(3,:));
      ww = mean(S(3,:));
      zz = mean(S(2,:));
      rr = mean(mean(Xsub));
      printf('%s (%d) \t \t -> %f\t %f \t %f \t %f \t %f \t %f \n', key,i, uu, vv, yy, ww, zz, rr);
      fflush(stdout);
      result(end+1,:)=[i uu vv ww zz rr];
      i = i +1;
      
      if plotme==1
        figure
        s=plotMedianQ(X, 'r');
        title(key);
      endif
      
    endif
    lastkey=key;
  catch
	printf('error');
	key = substr(line, 1, rindex(line, '_'))
	lastkey='';
  end_try_catch

    line = fgetl (fid);  
endwhile

save 'results.best_param' result;
printf('results.best_param saved.\n');


printf('##########################################################\n');
printf('##########################################################\n');
printf('##########################################################\n');

if length(find(result(:,2) == 1)) > 0 
	result(find(result(:,2) != 1),:)=[];
endif

format short
output_max_field_width(180)
%fixed_point_format(1)

sortrows(result, [3,  -4])

printf('##########################################################\n');
printf('##########################################################\n');
printf('##########################################################\n');

sortrows(result, [-5, 3])

printf('##########################################################\n');
printf('##########################################################\n');
printf('##########################################################\n');

sortrows(result, -6)

if plotme
	input("press a key");
endif

