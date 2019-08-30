% Strategy < handle
%
% Strategy properties:
%   nChan - nr. of logical channels [15]
%   fs    - sample rate; Hz [17400] 
%   pulseWidth - duration of a single stimulation phase; ns [18]
%   verbose - text output during execution (0/1)? [1] 
%   enablePuChangeListenersByDefault - automatically create all possible
%       property change listeners when adding ProcUnits to this
%       strategy? [boolean] [true]
%   procUnits - cell array of ProcUnit; read-only
%   executionOrder - order in which procUnits are executed; read-only
%   
% Strategy methods:
%   connect - create connection between an output and input data unit
%   run - execute entire coding strategy
%   resetData - delete all data 
%   resetDataGenerated - delete all data that gets set during strategy execution
%                        (but not user-defined input data)  
%   addProcUnit - add ProcUnit to Strategy
%   findProcUnit - return the ProcUnit object with matching ID string
%
% Strategy events:
%   GraphChanged - triggered when units or connections are added, data
%                  assigned or reset

% Change log:
% 11/05/2015, P.Hehrmann - created 
% 26 Jun 2017, PH - make Strategy subclass of handle (not dynamicprops)
% 29 Jun 2017, PH - change resetDataGenerated method (delegate propagation
%                   to ProcUnit.propagateOutput)
% 02 Aug 2019, PH - added documentation
classdef Strategy < handle 
   
    properties
        nChan = 15;  % nr. of logical channels [15]
        fs = 17400;  % sample rate; Hz [17400]
        pulseWidth = 18; %  duration of a single stimulation phase; ns [18]
        verbose = 1; % text output during execution (0/1)? [1]
        enablePuChangeListenersByDefault = true; % add all possible change listeners for PUs added to this strategy?
    end
    
    properties(SetAccess=private)
        procUnits = {}; % cell array of ProcUnits contained in the strategy
        executionOrder = []; % order in which ProcUnits are executed
    end 
        
    properties(Constant)
        PULSE_QUANT = 44/49; % quantization step (clock rate) for pulse widths [us]
    end
    
    events
        GraphChanged; % strategy graph has changed: units, connections, data
    end
    
   methods(Access=private)
       function updateExecutionOrder(obj)
       % Determine execution order by sorting ProcUnits according to their depth property 
         depths = cellfun(@(x) x.depth, obj.procUnits); % obtain depth of each unit within connection graph
         [~, order] = sort(depths, 'ascend'); % sort units according to depth
         obj.executionOrder = order;
       end
   end  
   
   methods  
       function obj = Strategy()
       % obj = Strategy()
       % Class constructor.
       end
       
       function addProcUnit(obj, unit)
       % addProcUnit(obj, unit)
       % Add ProcUnit to strategy. unit must have a unique ID string among
       % the existing ProcUnits of the strategy. The parent of unit must
       % be equal to obj.
       % NB: This method should not (need to) be called by the user!
           assert(isempty(obj.findProcUnit(unit.ID)), 'Strategy already contains ProcUnit with ID ''%s''.', unit.ID); 
           assert(unit.parent == obj || isempty(unit.parent), 'Unit ''%s'' already has differetn parent.', unit.ID); 
           
           obj.procUnits{end+1} = unit; % add new unit
           obj.executionOrder(end+1) = length(obj.procUnits); % new unit is executed last by default
           
           unit.parent = obj;
           
           if obj.enablePuChangeListenersByDefault
                unit.setChangeListeners();
           end
           
           notify(obj,'GraphChanged');
       end     
       
       function connect(obj, srcUnit, srcPort, destUnit, destPort)
       % Syntax:
       %   1. connect(obj, srcUnit, srcPort, destUnit, destPort)
       %   2. connect(obj, srcUnit, destUnit, destPort)
       %   3. connect(obj, srcUnit, destUnit, destPort)
       %   4. connect(obj, srcUnit, destUnit)
       % Create connection between an output port of s source ProcUnit to an
       % input port of a destination ProcUnit. When a port number is not
       % specified (cases 2 - 4), port 1 is assumed by default. 
           if nargin == 3
               obj.connect(srcUnit, 1, srcPort, 1);
               return
           end
           
           if nargin == 4
                if isscalar(srcPort) && isnumeric(srcPort) 
                    obj.connect(srcUnit, srcPort, destUnit, 1);
                else
                    obj.connect(srcUnit, 1, srcPort, destUnit);
                end
                return
           end
       
           assert(isa(srcUnit,'ProcUnit')|| ischar(srcUnit), 'srcUnit must be a ProcUnit object or ID string');
           assert(isa(destUnit,'ProcUnit')|| ischar(destUnit), 'destUnit must be a ProcUnit object or ID string');       
           assert(isscalar(srcPort), 'srcPort must be a scalar');
           assert(isscalar(destPort), 'destPort must be a scalar');
           
            % get ProcUnit objects from IDs if necessary 
           if ischar(srcUnit)
               srcUnit = obj.findProcUnit(srcUnit, true);
           end
           if ischar(destUnit)
               destUnit = obj.findProcUnit(destUnit, true);
           end
           
           srcUnitIndex = find(cellfun(@(x) x == srcUnit, obj.procUnits));
           destUnitIndex = find(cellfun(@(x) x == destUnit, obj.procUnits));
           duSrc = srcUnit.getOutputUnit(srcPort);
           duDest = destUnit.getInputUnit(destPort); 

           assert(srcUnit.parent == obj, 'The parent of source must be the called strategy object.')
           assert(destUnit.parent == obj, 'The parent of destination must be the called strategy object.')
           assert(isempty(duDest.connection), 'Destination DataUnit is already connected.');
           
           % Add new connection to source and destinastion DataUnits
           newCon = Connection(srcUnit, srcUnitIndex, duSrc, srcPort, destUnit, destUnitIndex, duDest, destPort);
           duDest.addConnection(newCon);
           duSrc.addConnection(newCon);
     
           destUnit.updateDepth(srcUnit.depth+1);
           
           obj.updateExecutionOrder();
           notify(obj,'GraphChanged');
       end
       
       function [pu, ind] = findProcUnit(obj, ID, throwError)
       % [pu, ind] = findProcUnit(obj, ID [, throwError])
       % Retrieve ProcUnit object from strategy by its ID
       % Input:
       %    ID - ID string of the ProcUnit
       %    throwError - throw error if ID not found? (boolean, default: false)
       % Output:
       %    pu  - ProcUnit object
       %    ind - index of pu within the procUnits array of the strategy
           if nargin < 3
               throwError = false;
           end
           % search ProcUnit
           pu = [];
           for ind = 1:length(obj.procUnits)
               if strcmp(obj.procUnits{ind}.ID, ID)
                   pu = obj.procUnits{ind};
                   break
               end
           end
           % if unsuccessful...
           if isempty(pu)
               if throwError
                   error('No ProcUnit with ID ''%s'' found.', ID);
               else
                   ind = [];
               end
           end
       end
       
       function run(obj, force)
       % run(obj, force)
       % Execute entire coding strategy by calling the run() method of all
       % contained ProcUnits in turn and propagating their outputs according
       % to the defined connections. The execution order is determined
       % automatically ensuring serial dependencies are taken into account.
       % Input:
       %    obj - ProcUnit handle
       %    force - force execution of all ProcUnits, overriding the automatic
       %            change detection mechanism [boolean]
           if nargin == 1
               force = false;
           end
           for i = obj.executionOrder 
               % get the next procUnit
               puCur = obj.procUnits{i};
               if obj.verbose
                    fprintf(1, 'ProcUnit: %s\n', puCur.ID);
               end
               % execute procUnit
               if puCur.modified || force
                   puCur.run();
                   puCur.resetModified();
               elseif obj.verbose
                  fprintf(1, '\b [skipped]\n');
               end
               % propagate output to connected units
               puCur.propagateOutput();
           end
       end	   
	   
       function resetData(obj)
       % resetData(obj)
       % Reset the input and output DataUnits of all ProcUnits
         for i=1:length(obj.procUnits)
            obj.procUnits{i}.resetDataUnits();
         end
       end       
       
	   function resetDataGenerated(obj)
       % resetDataGenerated(obj)
       % Reset the output of all ProcUnits, and the input of all ProcUnits except the roots of the Strategy
           for k=1:length(obj.procUnits)  % for every ProcUnit in the stragey:
               pu = obj.procUnits{k};
               pu.resetOutputs();
               pu.propagateOutput();
           end
       end
       
       function set.pulseWidth(obj, pw)
       % pwQuant = set.pulseWidth(obj, pw)
       % Set Strategy pulse width to desired value, quantized to integer an
       % integer multiple of Strategy.PULSE_QUANT
       % Input:
       %    obj - ProcUnit handle
       %    pw - target pulse width [us]
           assert(pw > 0, 'Pulse width must be positive');
           if ~isempty(obj.PULSE_QUANT) && obj.PULSE_QUANT > 0
               pw = round(pw / obj.PULSE_QUANT) * obj.PULSE_QUANT;
               pw = max(pw, obj.PULSE_QUANT);              
               obj.pulseWidth = pw;
           else
               obj.pulseWidth = pw;
           end           
       end
       
   end  % methods
   
end % classdef