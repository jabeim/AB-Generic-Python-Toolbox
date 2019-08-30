function factor = computeSynScaling(nFft, nHop, anaWin, synWin, nFramesForEst)

winAnaSyn = synWin(:) .* anaWin(:);

% generate "windowed" envelope
nRep = ceil((nFft/nHop)*(nFramesForEst)) + ceil(nFft/nHop);
sumSqEnv = unbuffer( repmat(winAnaSyn, 1, nRep), nHop);

% reduce to central part
sumSqEnv = sumSqEnv( ceil(nFft/nHop)*nHop : end-nFft+1);

% compute gain
factor = 1/sqrt(mean(sumSqEnv.^2));
end
