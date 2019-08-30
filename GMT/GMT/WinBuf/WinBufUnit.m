% WinBufUnit < ProcUnit
% Divide an input signal vector into overlapping buffers with a window
% function applied.
%
% WinBufUnit properties:
%  bufOpt - initial buffer state prior to signal onset. 'nodelay' start
%            buffering with first full input frame; [] for leading zeros; 
%            vector of length (nFft-nHop) to define arbitrary state.
%
% Input ports:
%   #1 - input signal vector (row or column). If matrix, assume it's a
%        multichannel signal where the longest dimension is time 
% Output ports:
%   #1 - matrix of buffered signal frames, NFFT x nFrames, or if
%        multichannel, a NFFT x nFrames x channels tensor.

% Change log:
%  Apr 2012, M.Milszynski - created
%  24/07/2012, P.Hehrmann - provide unscaled buffers on (optional) output port 3
%  19/10/2012, PH - provide "pro forma" scale of 0 on port 4 
%  28/08/2013, PH - constructor now works with 2 or 3 arguments; 
%                  4 args are unncessary but kept for backwards compatibility
%  25/11/2014, PH - removed scale output altogether (1 output only); 
%                   added documentation
%  19/12/2014, PH - 'run' adjusted to new ProcUnit interface (getInput, setOutput)
%  29/05/2015, PH - adapted to May 2015 framework: shared props removed
%  22/Jun/2017, PH - SetAccess=immutable properties
%  14 Aug 2019, PH - swapped winBufFunc arguments
classdef WinBufUnit < ProcUnit

    properties (SetAccess = immutable)
        bufOpt = []; 
    end
    
    methods
        function obj = WinBufUnit(parent, ID, bufOpt)
            obj = obj@ProcUnit(parent, ID, 1, 1);
            if nargin > 2
                obj.bufOpt = bufOpt;
            end
        end
        
        function run(obj)
           signalIn = obj.getInput(1);
           buf = winBufFunc(obj, signalIn);
           obj.setOutput(1, buf);                      
        end
    end
end