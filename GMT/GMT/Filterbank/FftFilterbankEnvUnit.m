% FftFilterbankEnvUnit < ProcUnit
% Compute frame-by-frame envelope values of an FFT-based filterbank.
% Filterbank channels are defined by parameter mapFft2Ch.
% 
% Properties
%  *mapFft2Ch - Frequency-to-channel mapping [see below] [[]]
%               EITHER: a 2-el. vector, specifying (1) the number of channels 
%                   for a F120 filterbank (3..15) and (2) extended low (0/1);
%               OR: scalar, specifying the number of ch. for a F120 filterbank
%                   w/o ext. low, OR: an nCh x nFft mixing matrix (linear weights, >= 0)
%               OR: an nCh x nFft mixing matrix (linear weights, >= 0)
%               OR: []  to use the strategy's startBin / nBinLims channel
%                   allocation (default)
% Input Ports:
%    #1  - FFT coefficient matrix (nFreq x nFrames)
% Output Ports:
%    #1  - linear envelopes (nCh x nFrames)
%
% See also: fftFilterbankEnvFunc.m

% Change log:
% 25/07/2012, P.Hehrmann - created
% 12/09/2012, PH - added documentation, matching changes to fftFilterBankFunc.m
% 24/11/2014, PH - removed "scale" input
% 19/12/2014, PH - 'run' adjusted to new ProcUnit interface (getInput, setOutput)
% 01/06/2015, PH - adapted to May 2015 framework: removed shared props
% 21/Jun/2017, PH - SetObservable properties
classdef FftFilterbankEnvUnit < ProcUnit
    properties (SetObservable)
        mapFft2Ch = []; % EITHER: a 2-el. vector, specifying (1) the number of channels for a F120 filterbank (3..15) and (2) extended low (0/1); OR: scalar, specifying the number of ch. for a F120 filterbank w/o ext. low, OR: an nCh x nFft mixing matrix (linear weights, >= 0) OR []  to use the strategy's startBin / nBinLims channel allocation 
    end
    
    methods
        function obj = FftFilterbankEnvUnit(parent, ID, mapFft2Ch)
            % obj = FftFilterbankEnvUnit(parent, ID, mapFft2Ch)
            obj = obj@ProcUnit(parent, ID, 1, 1);
            if nargin > 2
                obj.mapFft2Ch = mapFft2Ch;    
            end
        end
        
        function run(obj)
            X = obj.getInput(1);
            
            Y = fftFilterbankEnvFunc(X, obj);
            
            obj.setOutput(1, Y);
        end
    end
end