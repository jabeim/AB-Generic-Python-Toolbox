%SUBSAMPPROCUNIT A ProcUnit that subsamples inputs at an integer rate. 
% Overloads the setInput method of ProcUnit to subsample with specified
% factor (dsFactor) and initial offset / skip count (dsSkip). The output
% can (and will by default) be upsampled to the original rate and length.
%
% dsFactor, dsSkip and upsampleOutout are immuatble once the object is created.
%
% SubsampProcUnit properties:
%   dsFactor - integer downsampling factor 
%   dsSkip   - integer number of leading input frames to skip; for vector
%              inputs, time is assumed to be the second dimension (i.e. columns)

% Change log:
% 04 Jul 2017, PH - created
classdef SubsampProcUnit < ProcUnit
   
    properties(SetObservable)
        initialValue; % initial value 
    end
    
    properties (SetAccess = immutable)
        dsFactor; % integer downsampling factor
        dsSkip = 0;  % integer number of leading input frames to skip (0 = none) [] [0]
        upsampleOutput = true; % up-sample output after processing (by dsFactor)? [bool] [true]
    end
    
    properties (SetAccess = private)
        inputLength = 0; % original length of the latest provided input
    end
    
    methods
        function  obj = SubsampProcUnit(parent, ID, nIn, nOut, dsFactor, dsSkip, upsampleOutput)
        % obj = SubsampProcUnit(parent, ID, nIn, nOut, dsFactor, dsSkip)
            assert( rem(dsFactor,1)==0 && dsFactor >= 0, 'dsFactor must be an integer >= 0');
            assert( rem(dsSkip,1)==0 && dsSkip >= 0, 'dsFactor must be an integer >= 0');
            
            obj = obj@ProcUnit(parent, ID, nIn, nOut);
            obj.dsFactor = dsFactor;
            obj.dsSkip = dsSkip;
            
            if nargin > 6
                obj.upsampleOutput = upsampleOutput;
            end
            
            obj.initialValue = repmat({0}, 1, nOut);
        end
        
        function data = setInput(obj, iIn, data)
        % data = setInput(obj, iInput, data)
            % store original length of input (# of time frames)
            if size(data,2) > 1
                obj.inputLength = size(data,2);
            else
                obj.inputLength = size(data,1);
            end
            data = setInput@ProcUnit(obj, iIn, data(:,(obj.dsSkip+1):obj.dsFactor:end));            
        end
        
        function dataUp = setOutput(obj, iOut, data)
        % data = setInput(obj, iInput, data)
            initVal = obj.initialValue{iOut}(:);
            if obj.upsampleOutput
                if isscalar(initVal)
                    nRepRow = size(data,1);
                else
                    nRepRow = 1;
                end
                initSegment = repmat(initVal, nRepRow, obj.dsSkip); % fill initial skipped frames with initial value
                dataUp = [initSegment, repelem(data, 1, obj.dsFactor)];  % repeat every column dsFactor times
                dataUp = dataUp(:,1:obj.inputLength); % ensure input and output have same length when upsampling
            else
                dataUp = data;
            end
            setOutput@ProcUnit(obj, iOut, dataUp);            
        end
    end
    
end

