% PROCUNITCLASSNAME < ProcUnit
% This section explains the purpose, behavior and interface in general terms.
%
% PROCUNITCLASSNAME properties:
%  *property1 - description of property1 [UNITS] [DEFAULT VALUE]
%   property2 - ...
%   [list all properties here; prefix * for SetObservable properties; specify type/units and default value]
% 
% PROCUNITCLASSNAME methods:
%   PROCUNITCLASSNAME(parent, id, ...) - constructor  (ADAPT to match constructor signature)
%   run() - execute processing
%   [list all methods here]
%
% Input ports:
%   #1 - description/dimensions of data expected at input port #1 [UNITS]
%
% Output ports:
%   #1 - description/dimensions of data stored at output port #1 [UNITS]
%
% See also: PROCFUNCNAME [refer to relevant functions/classes]

% Change log:
% DD/MM/YYYY, [initials] - [changes implemented]
classdef PROCUNITCLASSNAME < ProcUnit
    properties (SetObservable) % can be monitored for change by a listener
%       property1  % description 
    end
    
    properties (SetAccess=private) % can't be changed or monitored for change
%       property2 % description    
    end
    
    methods
        function obj = PROCUNITCLASSNAME(parent, id, args) 
            % obj = PROCUNITCLASSNAME(parent, id, args)
            % Class constructor.
            % Input:
            %   parent - containing Stragegy object  (ADAPT to most specific sub-class)
            %   id - string identifier
            %   ADD description of further args
            % Output:
            %   obj - new instance of class PROCUNITCLASSNAME
            
            % create object
            obj = obj@ProcUnit(parent, ID, 1, 1); % ADAPT no. of ports as needed
            
            % check inputs

            % add own funcionality here...
        end
        
        function run(obj)
            % ADAPT as necessary...
            x = obj.getInput(1);
            PROCFUNCCALL;
            obj.setOutput(1, y);
        end
    end
end