% Connection < handle
% Represents a connection between a source (output) and a destination (input) 
% DataUnit. Connection contains object handles and internal indices of both
% DataUnits and their parent ProcUnits.

% Change log:
%   17/12/2014, PH - created
classdef Connection < handle
    properties (SetAccess = private)
       srcUnit % source ProcUnit 
       srcUnitIndex % index of srcUnit in strategy.procUnits
       srcPort % source DataUnit
       srcPortIndex % index of srcPort in ProcUnit.output
       destUnit  % destination ProcUnit
       destUnitIndex % index of destUnit in strategy.procUnits
       destPort % destination DataUnit
       destPortIndex % index of destPort in ProcUnit.input
    end
    
    methods 
        function obj = Connection(srcUnit, srcUnitIndex, srcPort, srcPortIndex, destUnit, destUnitIndex, destPort, destPortIndex)
%       obj = Connection(srcUnit, srcUnitIndex, srcPort, srcPortIndex, destUnit, destUnitIndex, destPort, destPortIndex)
            obj.srcUnit = srcUnit;
            obj.srcUnitIndex = srcUnitIndex;
            obj.srcPort = srcPort;
            obj.srcPortIndex = srcPortIndex;
            obj.destUnit = destUnit;
            obj.destUnitIndex = destUnitIndex;
            obj.destPort = destPort;
            obj.destPortIndex = destPortIndex;
        end

    end
    
end