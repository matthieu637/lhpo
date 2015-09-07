function surfaceVar = plotMedianQ(Z, mcolor)

higher = statistics(Z)(4,:);
lower = statistics(Z)(2,:);
point2p=1:size(Z,2);

surfaceVar = patch([point2p fliplr(point2p)], [higher fliplr(lower)], mcolor, 'linewidth', 0, 'linestyle', ':'); hold on;
colori = get(surfaceVar, 'facecolor');
colori *= 0.6;
set(surfaceVar, 'facecolor', colori);

%set(surfaceVar, 'edgecolor', 'none');
%set(surfaceVar, 'linestyle', 'none');
%

plot(statistics(Z)(3,:), mcolor, 'linewidth', 3);

endfunction
