 
function final = moving_max_policy(X, higher_better=1, inter)

    final = zeros(size(X));
    for ind=1:size(X,1)
        for ep=1:size(X,2)
	    if higher_better
	            final(ind,ep) = max(X(ind,max(1, ep-inter):ep));
	    else
	            final(ind,ep) = min(X(ind,max(1, ep-inter):ep));
	    endif
        endfor
    endfor

endfunction
