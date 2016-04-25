function R=paraload(x)
	global valid_dirs
	global column
	R = load(valid_dirs{x,1})(:,column);
endfunction

