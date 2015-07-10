 
function final = save_best_policy(X)

    final = zeros(size(X));
    for ind=1:size(X,1)
        for ep=1:size(X,2)
            final(ind,ep) = max(X(ind,1:ep));
        endfor
    endfor


endfunction