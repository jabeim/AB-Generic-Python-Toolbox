function [env, envNoLog] = hilbertEnvelopeFunc(par, X)
% [env, envNoLog] = hilbertEnvelopeFunc(par, X)
% INPUT
%   - par: parameter object/struct
%   - X : short-time fft coefficient matrix, nFreq x nFrames
%
% FIELDS FOR PAR:
%   - outputOffset : scalar offset added to all channel outputs [log2]
%   - parent.nChan : number of analysis channels
%   - parent.startBin  : lowest fft-bin of the lowest analysis channel 
%   - parent.nBinLims  : number of FFT bins per analysis channel
%
% OUTPUT:
%   - env : hilbert envelopes, one row per channel

% Change log:
% 2012, MM - created
% 24/11/2014, PH - removed mandatory "scale" argument
% 08/01/2015, PH - renamed extractEnvelopeFunc -> hilbertEnvelopeFunc  
% 29/05/2015, PH - adapted to May 2015 framework: shared props removed
% 17/07/2019, PH - added par.outputOffset, removed scale input entirely,
%                  cleaned up / explained log correction constant
strat = par.parent;
nChan = strat.nChan;
startBin = strat.startBin;
nBinLims = strat.nBinLims;
upperBound = par.outputUpperBound;
lowerBound = par.outputLowerBound;

% required benv envelope-extrator (see Nogueira, 2009 and internal F120-doc for details)
X(1:2:end,:) = -X(1:2:end,:); % sign-flip every other FFT bin
L = size(X, 2);
env = zeros(nChan, L);
envNoLog = zeros(nChan, L);
bin = startBin;

numfullFrqBin = floor(nBinLims/4);
numpartFrqBin = mod(nBinLims, 4);
logFiltCorrect = [2233 952 62 0] / (2^10); % firmware constants are in Q10 format

logCorrect = logFiltCorrect + par.outputOffset + 16; % +16 in log2 power compensates for standard Harmony signal scaling:  
                                                     % 2^-7 (FFT length compensation) * 2^15 (Q15 input to log2 function)
                                                     %   = 2^8 rescaling of FFT (squared in power)
for i = 1:nChan 
    for j = 1:numfullFrqBin(i)
        sr = sum(real(X(bin:bin + 3, :)));
        si = sum(imag(X(bin:bin + 3, :)));
        env(i, :)= env(i, :) + (sr.^2) + (si.^2);
        bin = bin + 4;
    end
    sr = sum(real(X(bin:bin + numpartFrqBin(i) - 1, :)), 1);
    si = sum(imag(X(bin:bin + numpartFrqBin(i) - 1, :)), 1);
    env(i, :) = env(i, :) + (sr.^2) + (si.^2);
    envNoLog(i, :) = env(i, :);
    env(i, :) = log2(env(i, :));

    if(nBinLims(i) > 4)
        % scaling factor is the same in each column
        env(i, :) = env(i, :) + logCorrect(4); 
    else
        env(i, :) = env(i, :) + logCorrect(nBinLims(i));
    end
    bin = bin + numpartFrqBin(i);
end

ix = ~isfinite(env);
env(ix) = 0;

env = max(min(env, upperBound), lowerBound);
