#!/usr/bin/octave -qf

arg_list = argv ();
file_to_load=arg_list{1};
plotme=str2num(arg_list{2});
column=str2num(arg_list{3});
save_best=str2num(arg_list{4});
higher_better=str2num(arg_list{5});

fid = fopen ("rules.out");
line = fgetl (fid); %ignore first line

line = fgetl (fid);
lastkey='';
i=1;
printf('\t \t \t \t -> max low quartile \t (ind) max low quartile \t median median \t mean median \t mean low quartile \t mean over 10 last percent \n');
clear result;
while line != -1
  try
    key = substr(line, 1, rindex(line, '_'));
    if( !strcmp(key, lastkey))
      X=load_dirs(key, file_to_load, column, save_best, higher_better);
      if size(X, 1) == 0
      	lastkey=key;
        line = fgetl (fid);
	continue
      endif
      Xsub = X(:, (end - floor(size(X,2)/10)):end);
      S=statistics(X);
      if higher_better
%	      [uu,vv]= max(S(2,:));
	      [uu,vv]= max(S(3,:));
      else
%     	      [uu,vv]= min(S(4,:));
     	      [uu,vv]= min(S(3,:));
      endif
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
	printf('error %s\n', line);
	key = substr(line, 1, rindex(line, '_'));
	lastkey='';
  end_try_catch

    line = fgetl (fid);  
endwhile

save 'results.best_param' result;
printf('results.best_param saved.\n');


printf('##########################################################\n');
printf('######## EPISODE NEEDED BY MEDIAN TO REACH BEST ##########\n');
printf('##########################################################\n');
printf('be sure the maximum is reached\n');
printf('no save best : ?? \n');
printf('save best : reach max performance quicker (may be unstable) \n');
printf('##########################################################\n');

if higher_better
	best_val = max(result(:,2));
	mult=1;
else
	best_val = min(result(:,2));
	mult=-1;
endif

subresult = result;
if length(find(result(:,2) == best_val)) > 0
	subresult(find(subresult(:,2) != best_val),:)=[];
endif

format short
output_max_field_width(180)
%fixed_point_format(1)

sortrows(subresult, [3,  -4]*mult)

printf('##########################################################\n');
printf('############### MEAN OF LOWER MEDIAN #####################\n');
printf('##########################################################\n');
printf('if first measure not valid | more convergent/stability measure \n');
printf('##########################################################\n');

sortrows(result, [-5, 3]*mult)

printf('##########################################################\n');
printf('######## MEAN OF PERF OF LAST 10 PERCENT EPISODE  ########\n');
printf('##########################################################\n');
printf('no save best : convergent measure\n');
printf('save best : max performance measure (poor discriminative) \n');
printf('##########################################################\n');

sortrows(result, -6*mult)

if plotme
	input("press a key");
endif

