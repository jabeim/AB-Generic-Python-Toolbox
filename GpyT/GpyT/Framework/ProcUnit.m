% ProcUnit < handle
%
% ProcUnit properties:
%   parent - parent Strategy object (or sub-class thereof)
%   verbose - provide extended console output? [boolean] [false]
%   inputCount - number of input ports
%   outputCount - number of output ports
%   ID - ID string (unique amongst all PrucUnit belonging to parent strategy)
%   depth - depth of this unit within parent Strategy (i.e. longtest possible path to a root)
%   changeListeners - array of active property change listeners
%   MODIFIED_RESETVAL - reset value for function resetModified() [boolean] [false]
%   modified - dynamic flag: has unit been modified since last run of parent? [boolean] [true]
%   input - array of input DataUnits
%   output - array of output DataUnits
%   debugData - any debug information (optionally) provided by the implementation of the run() method
%   debugRequest - local variables requested to be returned in debugData after calling run() [cells of strings]
%                  Each var should be returned as a field of struct debugData; However, compliance is optional 
%                  and up to the programmer of the specific subclass
% ProcUnit methods:
%   updateModified(obj, mod) - Sets the ProcUnit's modified 
%                   property to true if obj.mod OR mod are true, and 
%                   triggers parent GraphChanged event
%   resetModified(obj) - Sets the ProcUnit's modified property to
%                   obj.MODIFIED_RESETVAL and triggers parent GraphChanged event 
%   setChangeListeners(obj [, pNames]) - Creates PostSet property change 
%                   listeners for the class properties specified in cell array pNames
%   clearChangeListeners(obj) - Delete all existing property change listeners for obj
%   hasParent(obj) - Returns true iff the object's "parent" property is set (i.e. not empty)
%   addDataUnit(obj, type) - Add a DataUnit to obj. type can be either 'input' or 'output' 
%   getDataUnit(obj, ID) - Return DataUnit object with matching ID string
%   data = getData(obj, ID) - Return data contained in DataUnit with matching string
%   getInputUnit(obj, n) - Return n-th input DataUnit 
%   getInput(obj, n) - Return data contained in n-th input DataUnit
%   getInputs(obj) - Return data of all input DataUnits in a cell array
%   getOutputUnit(obj, n) - Return n-th output DataUnit 
%   getOutput(obj, n) - Return data contained in n-th output DataUnit
%   getOutputs(obj) - Return data of all output DataUnits in a cell array
%   setInput(obj, data, n) - Set data of n-th input DataUnit
%   setOutput(obj, data, n) - Set data of n-th output DataUnit
%   setData(obj, ID, data) - Set data of DataUnit with matching ID
%   resetDataUnit(obj, ID) - Reset DataUnit with matching ID. 
%   resetDataUnits(obj) - Reset all DataUnits
%   resetOutputs(obj) - Reset all output DataUnits
%   resetInputs(obj) - Reset all input DataUnits
%   propagateOutput(obj) - Propagate data of all output DataUnits to all 
%                          connected (receiving) input DataUnit 
%   updateDepth(obj, minDepth, nPrevSteps) - Increase "depth" of obj to
%                       minDepth if necessary and trigger update of all descendants of obj.
%   run - [abstract] read input, execute processing and store result in outputs
%
% See also: Strategy

% Change log:
% 17/09/2012, P.Hehrmann - notify parent strategy of the following graph changes: 
%                          DataUnits being reset, set, or output being propagated
% 06/12/2012, PH - added 'verbose' property (default = 0) to enable/disable
%                  "non-critical" output to the console
% 25/01/2013, PH - bug fix: resetDataUnits
% 28/08/2013, PH - added "depth" property and "updateDepth" method
% 27/10/2014, PH - bug fix: propagateOutput doesn't access output data
%                           unless a connection exists
% 19/12/2014, PH - changed: propagateOutput, updateDepth (changed connection mechanism)
%                  removed method: connectToInput 
%                  added methods: getInput, getOutput, getInputUnit, getOutputUnit, setOutput, setInput
% 19/08/2015, PH - getInput/Output, setInput/Output: 'n' optional, default n=1 
% 20/Jun/2017, PH - added "modified" property 
%                 - added updateModified method which parent notification exclusively
%                 - constructor creates "PostSet" change listeners for all SetObservable
%                   propties in subclasses of ProcUnit (calling updateModified in turn)
%                 - make ProcUnit subclass of handle (not dynamicprops)
%                 - add listeners for changes to DataUnit.data (set modified=true)
% 28 Jun 2017, PH - remove listeners for DataUnit.data, instead allow
%                   access to DataUnit.data through ProcUnit exclusively
%                   and handle updating of obj.modified explicitly in the respective
%                   functions
%                 - move creation of PostSet listeners from PU constructor
%                   to Strategy.addProcUnit() 
% 18 Jul 2017, PH - added protected MODIFIED_RESETVAL property, the value
%                   to which "resetModified" sets the "modified" property
%                   when called. Allows subclasses to enforce execution of
%                   run by the strategy's run method by setting it to true
%                 - removed obsolete updateParent() and getImpactedPropertyName() method
%                 - added class documentation
% 24 Oct 2017, PH - added getInputs() / getOutputs()
% 18 Jan 2018, PH - added debugRequest field
% 24 Jan 2018, PH - added initState field
%                 - added methods saveVarToStruct, retrieveVarFromStruct
classdef ProcUnit < handle
    properties
       parent; % parent Strategy object (or sub-class thereof) 
       verbose = 0; % provide extended console output? (1/0)
       debugData = []; % data field to store arbitrary debug information from last call of run()
       debugRequest = {}; % local variables requested to be returned in debugData after calling run() [cells of strings]
    end
    properties (SetAccess = private)
        inputCount = 0;  % number of input ports
        outputCount = 0; % number of output ports
        ID; % ID string
        depth = 0; % depth of this unit within parent Strategy (i.e. longtest possible path to a root)
        changeListeners = []; % array of active property change listeners 
    end
    properties (SetAccess = protected)
        MODIFIED_RESETVAL = false; % reset value for function resetModified();
    end
    properties (SetAccess = private, SetObservable)
        modified = true;  % indicator flag: has unit been modified since last run of parent, i.e. does it need to be re-computed 
    end
    properties(SetObservable)
        initState = [];
    end
    properties (Access = private)
        input = DataUnit.empty(); % array of input DataUnits
        output = DataUnit.empty(); % array of output DataUnits
    end
    properties (Constant = true, Hidden = true)
        inputPref = 'INPUT_'; % string prefix for input units 
        outputPref = 'OUTPUT_'; % string prefix for output units
    end
    methods
        function obj = ProcUnit(parent, ID, nInputs, nOutputs)
        % obj = ProcUnit(parent, ID, nInputs, nOutputs)
        % Create ProcUnit with spec. number of inputs and outputs and adds
        % if to its parent strategy. "Modified" is set true, enforcing 
        % execution at next run of the parent. 
        %    parent: instance of Strategy (or a sub-class)
        %        ID: ID string, must be unique amongst units belonging to parent
        %    nInput: number of input units
        %   nOutput: number of output units
            obj.parent = parent;
            obj.ID = ID;
            if nargin >= 3
                for i=1:nInputs
                    obj.addDataUnit('input');
                    
                end
            end
            if nargin == 4
                for i=1:nOutputs
                    obj.addDataUnit('output'); 
                end
            end
            if obj.hasParent()
               parent.addProcUnit(obj); 
            end
         
            obj.modified = true;
        end
        
        function updateModified(obj, mod)
        % updateModified(obj, mod) sets the ProcUnit's modified property to
        % true if obj.mod OR mod are true, and triggers parent GraphChanged event
            obj.modified = obj.modified || mod;
            notify(obj.parent,'GraphChanged');
        end

        function resetModified(obj)
        % resetModified(obj) sets the ProcUnit's modified property to
        % obj.MODIFIED_RESETVAL and triggers parent GraphChanged event
            obj.modified = obj.MODIFIED_RESETVAL;
            notify(obj.parent,'GraphChanged');
        end        
        
        function setChangeListeners(obj, pNames)           
        % setChangeListeners(obj [, pNames])
        % Creates PostSet property change listeners for the class properties 
        % specified in cell array pNames. Those properties have to be 
        % defined as SetObservable in their resp. sub-class. If pNames is
        % unspecified, listeners are added for ALL defined SetObservable 
        % properties defined in subclasses of ProcUnit. 
        % All previously defined listeners are deleted prior to creating
        % the new ones.
            obj.clearChangeListeners(); 
            
            if nargin == 1
                mcPu =  ?ProcUnit;
                mcSub = metaclass(obj);
            
                % props only present in subclasses of PU 
                propSub = setdiff(mcSub.PropertyList, mcPu.PropertyList);
                propSub = propSub([propSub.SetObservable]);
                pNames = {propSub.Name};
            end           
            
            for iP = 1:length(pNames);
                addlistener(obj, pNames{iP}, 'PostSet', @(src, evt) obj.updateModified(true));
            end  
            obj.updateModified(true);
        end
        
        function clearChangeListeners(obj)
        % clearChangeListeners(obj)
        % Delete all existing property change listeners for obj and set 
        % obj.changeListeners to an empty array of type event.proplistener
            delete(obj.changeListeners);
            obj.changeListeners = event.proplistener.empty;
        end
        
    end
    methods (Access = protected)
        % o = hasParent(obj)
        % True iff the object's "parent" property is set (i.e. not empty)
        function o = hasParent(obj)
            o = ~isempty(obj.parent);
        end
        
    end
    
    methods (Access = private)
        % addDataUnit(obj, type)
        % Add a DataUnit to ProcUnit obj. type can be either 'input' or 'output' 
        function addDataUnit(obj, type)
            type = lower(type);
            obj.([type 'Count']) = obj.([type 'Count']) + 1;
            id = [obj.([type 'Pref']) num2str(obj.([type 'Count']))];
            
            % create new data unit and add to list
            duNew = DataUnit(obj, upper(type), id);          
            obj.(type)(obj.([type 'Count']), 1) =  duNew; 
        end    
    end
    
    methods        
        % du = getDataUnit(obj, ID)
        % Return DataUnit object with matching ID string
        function du = getDataUnit(obj, ID)
            tmp = textscan(ID, '%s', 'delimiter', '_');
            type = lower(tmp{1}{1});
            dataUnits = obj.(type);
            found = false;
            for i=1:length(dataUnits)             
                if strcmp(dataUnits(i, 1).ID, ID)
                    du = dataUnits(i, 1);
                    found = true;
                    break;
                end
            end
            if ~found
                error('No dataUnit with ID %s found', ID);
            end
        end
        % data = getData(obj, ID)
        % Return data contained in DataUnit with matching string
        function data = getData(obj, ID)
           du = obj.getDataUnit(ID);
           data = du.getData();
        end
             
        function du = getInputUnit(obj, n)
        % du = getInputUnit(obj, n)
        % Return n-th input DataUnit object
            du = obj.input(n);
        end
        
        function data = getInput(obj, n)
        % data = getInput(obj [, n])
        % Return data from n-th input DataUnit object; default: n=1
            if nargin == 1
                n = 1;
            end
            data = obj.input(n).getData();
        end
        
        function dataCell = getInputs(obj)
        % dataCell = getInputs(obj)
        % Return content of all input DataUnits in a cell array
            dataCell = cell(size(obj.input));
            for i = 1:length(dataCell);
                dataCell{i} = obj.input(i).getData();
            end
        end
        
        function du = getOutputUnit(obj, n)
        % du = getOutputUnit(obj [, n])
        % Return n-th output DataUnit object; default: n=1
            if nargin == 1
                n = 1;
            end
            du = obj.output(n);
        end
        
        function data = getOutput(obj, n)
        % data = getOutput(obj [, n])
        % Return data from n-th output DataUnit object; default: n=1
            if nargin == 1
                n = 1;
            end
            data = obj.output(n).getData();
        end
        
        function dataCell = getOutputs(obj)
        % dataCell = getOutputs(obj)
        % Return content of all output DataUnits in a cell array
            dataCell = cell(size(obj.output));
            for i = 1:length(dataCell);
                dataCell{i} = obj.output(i).getData();
            end
        end
        
        function data = setInput(obj, n, data)
        % 1. data = setInput(obj, n, data)
        % 2. data = setInput(obj, data)
        % Set data of n-th input DataUnit; default: n=1
            if (nargin == 2)
                data = n; % 'n' contains data, really
                n = 1;
            end
            du = obj.input(n);
            mod = du.setData(data);
            obj.updateModified(mod);
        end
        
        function data = setOutput(obj, n, data)
        % 1. data = setOutput(obj, n, data)
        % 2. data = setOutput(obj, data)
        % Set data of n-th output DataUnit; default: n=1
            if (nargin == 2)
                data = n; % 'n' contains data, really
                n = 1;
            end
            du = obj.output(n);
            du.setData(data);       
        end        
        
        function data = setData(obj, ID, data)
        % data = setData(obj, ID, data)
        % Set data of DataUnit with matching ID.
           du = obj.getDataUnit(ID);
           mod = du.setData(data);
           obj.updateModified(mod);
        end
        
        function resetDataUnit(obj, ID)
        % resetDataUnit(obj,ID)
        % Reset DataUnit with matching ID. 
            du = obj.getDataUnit(ID);
            du.resetData();
            obj.updateModified(true);
        end
        
        function resetDataUnits(obj)
        % Reset all input and output DataUnits    
            for din = obj.input(:)'
                din.resetData();
            end
            for dout = obj.output(:)'
                dout.resetData();
            end
            obj.updateModified(true);
        end
        
        function resetOutputs(obj)
        % Reset all output DataUnits    
            for du = obj.output(:)'
                du.resetData();
            end
        end
        
        function resetInputs(obj)
        % Reset all input DataUnits    
            for du = obj.input(:)'
                du.resetData();
            end
        end
        
        function propagateOutput(obj)
        % Propagate data of all output DataUnits to all connected (receiving) input DataUnit 
            for i=1:obj.outputCount
                du = obj.output(i);
                nCon = du.getNumberConnections();
                if nCon > 0
                    data = du.getData();
                    for j=1:nCon
                        target = du.connection(j).destPortIndex;
                        targetPu = du.connection(j).destUnit;
                        targetPu.setInput(target, data);
                    end
                end
            end
        end
        
        function d = updateDepth(obj, minDepth, nPrevSteps)
            % Increase depth of obj to minDepth if necessary and trigger
            % update of all descendants of obj. nPrevSteps is the recursion
            % depth and is used to avoid infinite loops
            if nargin < 3
                nPrevSteps = 0;
            end
            
            if nPrevSteps >= length(obj.parent.procUnits)-1
                error('Maximum recursion depth exceeded: strategy graph must be loopy.');
            end
      
            if minDepth > obj.depth
                obj.depth = minDepth;
                for DU = obj.output(:)'
                    for con = DU.connection(:)'
                       con.destUnit.updateDepth(obj.depth+1, nPrevSteps+1);
                    end
                end
            end
            d = obj.depth;    
        end
        
        function S = saveVarToStruct(obj, varargin)
            S = struct();
            nVar = length(varargin);
            for iVar = 1:nVar
                varName = varargin{iVar};
                S.(varName) = evalin('caller', varName);
            end
        end
    
        function retrieveVarFromStruct(obj, S)
            fieldNames = fieldnames(S);
            nVar = length(fieldNames);
            for iVar = 1:nVar
                varName = fieldNames{iVar};
                assignin('caller', varName, S.(varName));
            end
        end        
    end

    methods (Abstract)
        run(obj) % read input, execute processing and store result in outputs
    end
end