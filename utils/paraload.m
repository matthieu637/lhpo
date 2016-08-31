function R=paraload(x)
	global valid_dirs
	global column
	global higher_better
	global save_best
	global inter_moving
	R = load(valid_dirs{x,1})(:,column);
	if save_best == 1
		R = save_best_policy(R', higher_better)';
	elseif save_best == 2
		R = moving_max_policy(R', higher_better, inter_moving)';
	endif
endfunction

