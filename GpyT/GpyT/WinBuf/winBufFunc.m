function b = winBufFunc(par, signalIn)
% b = winBufFunc(par, signalIn)
% INPUT:
%   signalIn - samples of input signal obtained from e.g. wavread
%
% FIELDS FOR PAR:
%   parent.nFft - buffer size in samples (probably equal to FFT size)
%   parent.nHop - hop size in samples
%   parent.window - samples of window function
%   bufOpts - initial buffer state prior to signal onset. 'nodelay' start
%            buffering with first full input frame; [] for leading zeros; 
%            vector of length (nFft-nHop) to define arbitrary state.
%
% OUTPUT:
%   buf - buffers, one signal-frame per column

% Change log:
%  04/2012, M.Milczynski - created
%  27/04/2012, P.Hehrmann - removed call to circBuffer, replaced by buffer.m; 
%                           set opts = [] for equivalent behaviour
%  02/05/2012, PH - bug fix: scale is 0 ( =log2(1) ) for 'float'
%                           precision
%  24/09/2012, PH - set scale to 0 for maxima < 2^(-24) (re-enabled)
%  06/08/2013, PH - re-enable shared prop "precision" option; reduced memory load
%  25/11/2014, PH - remove scale output altogether
%  29/05/2015, PH - adapted to May 2015 framework: shared props removed
%  13/08/2018, J.Thiemann - Add multichannel support
%  14 Aug 2019, PH - swapped function arguments
strat = par.parent;

[M, N] = size(signalIn);
if N>M
%    warning('winBufFun: input signal wider than long (%dx%d). Transposing.', M, N);
    signalIn = signalIn.';
    N=M;
end

b = buffer(signalIn(:, 1), strat.nFft, strat.nFft-strat.nHop, par.bufOpt);
b = bsxfun(@times, b, strat.window);
if N>1
    temp = b;
    b = zeros(size(b, 1), size(b, 2), N);
    b(:, :, 1) = temp;
    
    for n=2:N
        b(:, :, n) = buffer(signalIn(:, n), strat.nFft, strat.nFft-strat.nHop, par.bufOpt);
        b(:, :, n) = bsxfun(@times, b(:, :, n), strat.window);
    end
end
