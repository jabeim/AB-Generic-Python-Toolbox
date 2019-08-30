% FftStrategy < Strategy
% Coding strategy that implements its filterbank using an FFT
%
% FftStrategy properties:
%   nFft - FFT length [256]
%   nHop - hop size [20]
%   windowType - FFT window used; string  ['blackhann']
%   startBin - index of 1st FFT bin in the lowest filterbank channel [one-based] [6]
%   nBinLims - 1 x nChan vector, nr of FFT bins per channel [int > 0] [default F120 allocation]

% Change log:
% 11/05/2015, P.Hehrmann - created
% 02 Aug 2019, PH - added comments and constructor
classdef FftStrategy < Strategy
    properties
        nFft = 256; % FFT length [samples] [256]
        nHop = 20;  % FFT hop size (stride) [samples] [20]
        windowType = 'blackhann';  % FFT window type used [string / function handle] ['blackhann']
        startBin = 6; % first FFT bin of lowest filterbank channel [1-based index] [6]
        nBinLims = [2, 2, 1, 2, 2, 2, 3, 4, 4, 5, 6, 7, 8, 10, 56]; % nr. of FFT bins per channel [1-based indices] [default F120 allocation]
    end
    
    properties(Dependent = true)
        window; % FFT window
        chanStartBin;  % start bin of each channel
        chanStopBin;   % stop bin of each channel
        chanCutoffLow;  % lower cutoff frequency per channel [Hz]
        chanCutoffHigh; % upper cutoff frequency per channel [Hz]
        chanCenterFreq; % center frequency, on linear scale, per channel [Hz]
        fftBinFreq; % center frequency of each FFT bin [Hz]
        fftBinLoc;  % nominal cochlear position for each FFT bin [# electrodes from most apical el.]
    end
    
    methods
        function obj = FftStrategy(varargin)
        % Class constructor
        % Use:
        %   obj = FftStrategy(extendedLow)
        %   obj = FftStrategy(startBin, nBinLims)
        %   obj = FftStrategy(fs, nFft, nHop, windowType, startBin, nBinLims) 
        % Input:
        %   extendedLow - use F120 extended low filter allocation [bool]
        %   fs - audio sample rate [Hz]
        %   nBinLims - nr. of FFT bins per channel [1-based indices]
        %   nFft - FFT length [samples] [256]
        %   nHop - FFT hop size (stride) [samples]
        %   startBin - first FFT bin of lowest filterbank channel [1-based index]
        %   windowType -  FFT window type used [string / function handle]
        % Output:
        %   obj - new instance of class FftStrategy
            switch nargin
                case 0
                    % nothing to do
                case 1
                    assert(isscalar(varargin{1}) && islogical(varargin{1}), 'Single argument extendedLow must be logical scalar');
                    if (varargin{1}) %  extended low filterbank: widen lowest channel
                        obj.startBin = 5;
                        obj.nBinLims(1) = 3;
                    end
                case 2
                    [startBin, nBinLims] = varargin{:};
                    assert(isscalar(startBin) &&  (rem(startBin,1) == 0) && (startBin > 0), ...
                           'startBin must be a positive integer.');
                    assert(isvector(nBinLims) && all(rem(nBinLims,1) == 0) && all(nBinLims > 0), ...
                           'nBinLims must be a vector of positive integers.');
                    
                    obj.nChan = length(nBinLims);
                    obj.nBinLims = nBinLims;
                    obj.startBin = startBin;
                case 6
                    [fs, nFft, nHop, windowType, startBin, nBinLims] = varargin{:};
                    assert(isscalar(fs) &&  (rem(fs,1) == 0) && (fs > 0), ...
                           'fs must be a positive integer.');                    
                    assert(isscalar(nFft) &&  (rem(nFft,1) == 0) && (nFft > 0), ...
                           'nFft must be a positive integer.');                    
                    assert(isscalar(nHop) &&  (rem(nHop,1) == 0) && (nHop > 0), ...
                           'nHop must be a positive integer.');                      
                    assert(ischar(windowType) || isa(windowType, 'function_handle'), ...
                           'windowType must be a string or function handle.')   
                    assert(isscalar(startBin) &&  (rem(startBin,1) == 0) && (startBin > 0), ...
                           'startBin must be a positive integer.');
                    assert(isvector(nBinLims) && all(rem(nBinLims,1) == 0) && all(nBinLims > 0), ...
                           'nBinLims must be a vector of positive integers.');
                    obj.fs = fs;
                    obj.nFft = nFft;
                    obj.nHop = nHop;
                    obj.nChan = length(nBinLims);
                    obj.nBinLims = nBinLims;
                    obj.startBin = startBin;   
                otherwise
                    help FftStrategy.FftStrategy;
                    error('Illegal number of constructor arguments.');
            end
        end
        
        function win = get.window(obj)
            win = generateWindow(obj.windowType, obj.nFft);
        end
        
        function ind = get.chanStartBin(obj)
            ind = obj.startBin + cumsum([0 obj.nBinLims(1:end-1)]);
        end
        
        function ind = get.chanStopBin(obj)
            ind = obj.startBin + cumsum(obj.nBinLims) - 1;
        end
        
        function freq = get.chanCutoffLow(obj)
            freq = obj.fs/obj.nFft * (obj.chanStartBin-1.5);
        end
        
        function freq = get.chanCutoffHigh(obj)
            freq = obj.fs/obj.nFft * (obj.chanStopBin-0.5);
        end
        
        function freq = get.chanCenterFreq(obj)
            freq = (obj.chanCutoffHigh + obj.chanCutoffLow) / 2;
        end
        
        function freq = get.fftBinFreq(obj)
            freq = obj.fs/obj.nFft * (0:obj.nFft/2);
        end
        
        function loc = get.fftBinLoc(obj)
            error('fftBinLoc methods not implemented yet.');
        end        
    end
    
end % classdef

