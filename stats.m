#!/usr/bin/octave -qf

dirs=glob('./[._0-9]*');

index=1;
for i=1:length(dirs)
	X=load(strcat(dirs{i,1}, '/statRL_NN.dat'));
	X = mean(X);
	headers=strsplit(strrep(dirs{i, 1},'./',''),'_');
	Z=length(headers);
	line=[];
	for j=1:length(headers)
		line(end+1)=str2num(headers{1,j});
	endfor
	line(end+1)=X(2);
	line(end+1)=X(4);
	line(end+1)=X(1);
	data(index,:)=line;
	index++;
endfor

function optimal =  pareto(X, begin)

for i=1:size(X, 1)
        existBetter=0;
        for j=1:size(X,1)
                if X(i,begin+1) < X(j,begin+1) && X(i,begin+2) < X(j,begin+2)
                        existBetter=1;
                        break
                endif
        endfor

        if existBetter == 0
                optimal(end+1,:)=X(i,:);
        endif
endfor

endfunction

optimal = pareto(data,Z)

[m, i ] = max(data(:,Z+1))

data(i,:)

