function R=parasbpload(x)
	global valid_dirs
	global column
	global higher_better
	B = load(valid_dirs{x,1})(:,column);
	R = save_best_policy(B', higher_better)';
endfunction
