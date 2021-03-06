				
function final = load_dirs (beforef,endf, colm, sb, hb=1, discre=-1, im=50, debug=0)
	if (nargin < 4 || not(ischar(beforef)) || not(ischar(endf)))
		printf('usage : load_dirs (path, file, column, save_best, higher_better)\n');
		printf("X=load_dirs ('.', '[0-9.]*learning.data', 6, 1, 0);\n");
		printf("X=load_dirs ('.', '[0-9.]*testing.data', 6, 1, 0);\n");
		final = [];
		return
	endif
	pattern = strcat(beforef, '[._0-9a-Z]*/', endf);
	if(debug==1)
		printf('looking for : %s\n', pattern);
	endif

	%or treatment
	if findstr(pattern, '||') > 0
		b_=findstr(pattern, '(');
		e_=findstr(pattern, ')');
		possi=substr(pattern, b_+1, e_- b_ -1);
		pattern=strrep(pattern, strcat('(',possi,')'), strsplit (possi, '||'));
	endif

  clear -g
	global valid_dirs;
	global column=colm;
	global higher_better=hb;
	global inter_moving=im;
	global discretize=discre;
%	global discretize=100;
	global save_best=sb;
	valid_dirs = glob(pattern);

% regex * doesn't count as zero
	if length(valid_dirs) == 0
		pattern = strcat(beforef, '/', endf);
		valid_dirs = glob(pattern);
	endif

	if(debug==1)
		valid_dirs
	endif

	if length(valid_dirs) == 0
		printf('ERROR path :%s \n', pattern);
		fflush(stdout);
		final = [];
		return
	endif

	%memory limits -
	if (discretize == -1)
		Y=load(valid_dirs{1,1})(:,column);
		if( (length(valid_dirs)*size(Y,1)) > 10^7.5)
			printf('WARNING matrix is too big > 10^7.5 I am going to shuffle it and take only a subpart\n');
			valid_dirs=valid_dirs(randperm(length(valid_dirs)));
			nsize=(10^7.5)/size(Y,1);
			valid_dirs = valid_dirs (1:nsize);
			clear Y;
		endif
	endif

	firstTry=1;
	while 1	
		if (length(pk = pkg('list', 'parallel')) == 0) || (firstTry != 1) || length(valid_dirs)==1
			for i=1:length(valid_dirs) 
				valid_dir = valid_dirs{i,1};
				X{i} = load(valid_dir)(:,column);
				if save_best == 1
					X{i} = save_best_policy(X{i}', higher_better)';
				elseif save_best == 2
					X{i} = moving_max_policy(X{i}', higher_better, inter_moving)';
				endif
				
				if(discretize != -1)
					X{i} = X{i}((1:(end/discretize))*discretize, :);
				endif
			endfor
			break
		else
			pkg load parallel
			vector_x=1:length(valid_dirs);
			try
				%fun = @(x) load(valid_dirs{x,1})(:,column); %cannot indexing in anonymous
				%function cannot be called fun
				X = pararrayfun(nproc, @paraload, vector_x, 'VerboseLevel', 0);
				final = X';
				return
			catch
				lasterror()
				printf('ERROR MERGE MATRIX ! try to analyse the following :\n');
				firstTry=0;
			end_try_catch
		endif
	endwhile
%  	keyboard
	base = size(X{1});
	mmin = base(1);
	minRequired=0;
	for i=2:length(valid_dirs)
	  if(size(X{i}, 2) != base(2) )
		printf('ERROR matrix columns differ to merge %s (%s)\n', pattern, valid_dirs{i,1});
		exit
	  elseif(size(X{i}, 1) != base(1))
		printf('WARNING matrix rows differ (min taken) %s (%s)\n', pattern, valid_dirs{i,1});
		mmin = min([mmin size(X{i}, 1)]);
		minRequired=1;
	  endif
	endfor

%  	keyboard
	
  final=zeros(length(valid_dirs), mmin);
  for i=1:length(valid_dirs)
          final(i,:) = X{i}(1:mmin);
  endfor

endfunction


%load_dirs('NN_APP', 'statRL_NN.dat')

