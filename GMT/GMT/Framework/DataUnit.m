% DataUnit < handle

% Change log:
% 14/09/2012, P.Hehrmann - added function "dataIsEmpty"
% 16/12/2014, PH - changed addConnection to handle port numbers and ID strings as
%                  argument.
% 21 Jun 2017, PH - enable overwriting data when current data is not empty 
% 26 Jun 2017, PH - setData returns "mod" flag: true if content changed
%                 - setData does not overwrite data if new and old content
%                   are identical
classdef DataUnit < handle
    properties (SetAccess = private)
        parent;
        ID;
        type;  % 'INPUT' or 'OUTPUT'
        connection = Connection.empty(0,0);
    end
    properties (Access = private)
        data = [];
    end
    
    methods (Access = {?ProcUnit, ?Strategy})
        function mod = setData(obj, data)            
            mod = ~isequal(data, obj.data);
            if mod
                obj.data = data;
            end         
        end
        
        function resetData(obj)
            obj.data = [];
        end
    end
    
    methods
        function obj = DataUnit(parent, type, ID)
            obj.parent = parent;
            obj.type = type;
            obj.ID = ID;
        end
        
        function addConnection(obj, con)
            assert(isa(con,'Connection'), 'con must be an instance of class Connection.')
            if strcmp(obj.type,'INPUT') && ~isempty(obj.connection)
                error('Attempt to create multiple connections to one input DataUnit.')
            end
            obj.connection(end+1) = con;
        end
        
        function data = getData(obj)
           data = obj.data;
        end
        
        function n = getNumberConnections(obj)
            n = length(obj.connection); 
        end
        
        function e = dataIsEmpty(obj)
            e = isempty(obj.data);
        end
    end

end
