% FftFilterbankUnit < ProcUnit
% Compute FFT on buffered signal segments.
%
% FftFilterbankUnit properties
%   combineDcNy - Combine DC and Nyquist bins into single complex 1st bin? [boolean] [false]
%                 if true, then bin #1 = .5*(DC+NY + i(DC-NY)) and bin #NFFT/2+1 = 0 
%   compensateFftLength - Divide FFT coefficients by nFft/2? [boolean] [false] 
%   includeNyquistBin - return bin #nFft/2+1 in output? [boolean] [false]  
% 
% Input Ports:
%   #1  - buffered signal frames, NFFT x nFrames
%
% Output Ports:
%   #1  - FFT coefficient matrix, (NFFT/2) x nFrames (default) or (NFFT/2+1) x nFrames, depending on includeNyquistBin
%
% See also: fftFilterBankFunc.m

% Change log:
% 2012, MM - created
% 24/11/2014, PH - added documentation, changed constructor syntax, 
%                  removed unused sharedProps, reduced to 1 input and
%                  output port
% 19/12/2014, PH - 'run' adjusted to new ProcUnit interface (getInput, setOutput)
% 01/08/2015, PH - renamed FFTFilterBankUnit -> FftFilterbankUnit,
%                  removed nInput/nOutput constructor args
% 29/05/2015, PH - adapted to May 2015 framework: shared props removed
% 25/04/2017, PH - added "combineDcNy" option
% 21/Jun/2017, PH - private set access to combineDcNy
% 21 Aug 2017, PH - add compensateFftLength property
% 01 Jun 2018, PH - add includeNyquistBin property
% 15 Aug 2019, PH - swapped fftFilterbankFunc arguments
classdef FftFilterbankUnit < ProcUnit
    
    properties (SetAccess = private)
        combineDcNy = false; % Combine DC and Nyquist bins into single complex 1st bin?
        compensateFftLength = false; % Divide FFT coefficients by nFft/2? [boolean]
        includeNyquistBin = false; % Return bin #nFft/2+1 in output? [boolean] 
    end
   
    methods
        function obj = FftFilterbankUnit(parent, ID, compensateFftLength, combineDcNy, includeNy)
        % obj = FftFilterbankUnit(parent, ID, compensateFftLength, combineDcNy)
            obj = obj@ProcUnit(parent, ID, 1, 1);
            if nargin > 2
                obj.compensateFftLength = compensateFftLength;
            end

            if nargin > 3
                obj.combineDcNy = combineDcNy;
            end
            if nargin > 4
                obj.includeNyquistBin = includeNy;
            end
        end
        function run(obj)
            buf = obj.getInput(1);
            X = fftFilterbankFunc(obj, buf);
            obj.setOutput(1, X);
        end
    end
end