 
function final = save_best_policy(X, higher_better=1)

    final = zeros(size(X));
    for ind=1:size(X,1)
        for ep=1:size(X,2)
	    if higher_better
	            final(ind,ep) = max(X(ind,1:ep));
	    else
	            final(ind,ep) = min(X(ind,1:ep));
	    endif
        endfor
    endfor


endfunction
