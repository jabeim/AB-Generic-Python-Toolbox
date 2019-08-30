% SpecPeakLocatorUnit < SubsampProcUnit
% Estimate dominant (peak) frequency and corresponding cochlear location for
% each channel of the coding strategy. Peak frequency estimates are
% obtained by quadratic interpolation of the frequency spectrum around the
% highest-energy FFT bin per channel. Target locations are computed from
% the peak frequencies by piece-wise linear interpolation, with nodes 
% defined for the center frequencies of each STFT bin.
%
% Properties:
%   binToLocMap - 1 x nBin matrix of nominal cochlear locations for the center
%                 frequencies of each STFT bin [ascending within [0,15]] [F120 firmware setting]
%
% Input Ports:
%  #1 - nBin x nFrames matrix of STFT coefficients 
%
% Output Ports:
%  #1 - nChan x nFrames matrix of peak frequency estimates [Hz]
%  #2 - nChan x nFrames matrix of corresponding cochlear locations [within [0,15]]
% 
% See also: specPeakLocatorFunc.m, SubsampProcUnit.m, ProcUnit.m, FftStrategy.m

% Change log:
% 2012, MM - created
% 09/01/2015, PH - use getInput /setOutput instead getData/setData,
%                  removed nInput/nOutput constuctor args
% 29/05/2015, PH - adapted to May 2015 framework: shared props removed
% 30 Jul 2019, PH - add binToLocMap as configurable parameter
%                 - make SpecPeakLocator sub-class of SubsampProcUnit
%                 - add documentation
classdef SpecPeakLocatorUnit < SubsampProcUnit
    properties (Constant)
        DEF_DSFACT = 3; % default down-sampling factor [int > 0] [3]
    end
    
    properties(SetObservable)
        binToLocMap = [zeros(1,6), 256, 640, 896, 1280, 1664, 1920, 2176, ...   % 1 x nBin vector of nominal cochlear locations for the center frequencies of each STFT bin
              2432, 2688, 2944, 3157, 3328, 3499, 3648, 3776, 3904, 4032, ...   % as in firmware; values from 0 .. 15 (originally in Q9 format)
              4160, 4288, 4416, 4544, 4659, 4762, 4864, 4966, 5069, 5163, ...   % corresponding to the nominal steering location for each 
              5248, 5333, 5419, 5504, 5589, 5669, 5742, 5815, 5888, 5961, ...   % FFT bin
              6034, 6107, 6176, 6240, 6304, 6368, 6432, 6496, 6560, 6624, ...
              6682, 6733, 6784, 6835, 6886, 6938, 6989, 7040, 7091, 7142, ...
              7189, 7232, 7275, 7317, 7360, 7403, 7445, 7488, 7531, 7573, ...
              7616, 7659, 7679 * ones(1,53)] / 512;
    end
    
    methods
        function obj = SpecPeakLocatorUnit(parent, ID, dsFactor, dsSkip, upsampleOutput)
            % obj = SpecPeakLocatorUnit(parent, ID [, dsFactor [, dsSkip [, upsampleOutput]]])
            % Class constructor.
            % Input:
            %   parent - containing FftStrategy object
            %   ID - string identifier
            %   dsFactor - down-sampling factor [int > 0] [3]
            %   dsSkip - nr of initial frames to skip when downsampling [int > 0] [2]
            %   upsampleOutput [boolean] [true]
            % Output:
            %   obj - new instance of class SpecPeakLocatorUnit            
            if nargin < 3
                dsFactor = SpecPeakLocatorUnit.DEF_DSFACT;
            end
            if nargin < 4
                dsSkip = dsFactor-1;
            end
            if nargin < 5
                upsampleOutput = true;
            end
            
            obj = obj@SubsampProcUnit(parent, ID, 1, 2, dsFactor, dsSkip, upsampleOutput);
        end
        
        function run(obj)
            stft = obj.getInput(1);         
            [freq, loc] = specPeakLocatorFunc(obj, stft);
            obj.setOutput(1, freq);
            obj.setOutput(2, loc);         
        end
    end
end