%f version
function final = load_dirs (file)
	valid_dirs = glob(strcat('./[._0-9]*/', file));

%  	valid_dirs

	for i=1:length(valid_dirs) 
		valid_dir = valid_dirs{i,1};
		X{i} = load(valid_dir);
	endfor

	if(length(valid_dirs) == 0)
		printf('ERROR path :%s \n', pattern);
		exit
	endif

%  	keyboard

	base = size(X{1});
	mmin = base(1);
	minRequired=0;
	for i=2:length(valid_dirs)
	  if(size(X{i}, 2) != base(2) )
		printf('ERROR matrix columns differ to merge %s\n', pattern);
		exit
	  elseif(size(X{i}, 1) != base(1))
		printf('WARNING matrix rows differ (min taken) %s\n', pattern);
		mmin = min([mmin size(X{i}, 1)]);
		minRequired=1;
	  endif
	endfor

%  	keyboard
	
	if( minRequired == 0)
	  final=zeros(size(X{i}));
	  %size(final)
	  for i=1:length(valid_dirs)
		  final += X{i};
	  endfor
	  %size(final)
	else
	  final=zeros(mmin, size(X{i}, 2));
	  %size(final)
	  for i=1:length(valid_dirs)
		  final += X{i}(1:mmin, :);
	  endfor
	  %size(final)
	endif

	final = final / length(valid_dirs);

endfunction


%load_dirs('NN_APP', 'statRL_NN.dat')

