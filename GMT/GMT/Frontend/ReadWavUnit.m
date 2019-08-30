% ReadWavUnit < ProcUnit
% 
% Read wav data from file. 
%
% Input Ports: none
%
% Output Ports:
%   #1  - column vector contained wav data
%
% ReadWavUnit Properties:
%  *wavFile - wav file name
%  *tStartEnd - 2-element vector specifying start and end time of the
%              section to be read [seconds]
%  *iChannel - index of channel to be returned [integer] [1]
%
% ReadWavUnit Methods:
%   ReadWavUnit - constructor

% Change log:
%  Apr 2012, M.Milczynski - created
%  12 Dec 2012, P.Hehrmann - defaults for nInput, nOutput
%  14 Jan 2012, PH - wav file can now be specified either by an input
%                 DataUnit (previous behavior), or by propterty 'wavFile' 
%                 (new behavior); might deprecate old behavior for
%                 release version
%  19 Dec 2014, PH - 'run' adjusted to new ProcUnit interface (getInput, setOutput)
%  09/01/2015, PH - remove nInput/nOutput constructor args; 
%                   removed option to specify wav file name as input data 
%  18/01/2015, PH - add property tStartEnd
%  29/05/2015, PH - adapted to May 2015 framework: shared props removed
%  29/02/2016, PH - added iChannel
%  23 Jun 2017, PH - SetObservable properties
%  28 Jun 2017, PH - AbortSet properties
classdef ReadWavUnit < ProcUnit
    
    properties (SetObservable, AbortSet)
        wavFile = '';  % wav file name
        tStartEnd = []; % 2-el vector defining start and end time of section to be read; sec
        iChannel = 1;
    end
    
    methods
        function obj = ReadWavUnit(parent, ID, wavFile, tStartEnd, iChannel)
        % obj = ReadWavUnit(parent, ID, wavFile, tStartEnd)
        % Constructor, generate new ReadWavUnit object
        
        obj = obj@ProcUnit(parent, ID, 0, 1);
               
            if (nargin > 2)
                obj.wavFile = wavFile;
            end
            
            if (nargin > 3)
                obj.tStartEnd = tStartEnd;
            end
            
            if (nargin > 4)
                obj.iChannel = iChannel;
            end
        end
        
        function run(obj) 
            signalIn = readWavFunc(obj);
            obj.setOutput(1, signalIn);
        end
    end
end