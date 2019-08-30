% ElementwiseUnit < ProcUnit
% Computes an arbitrary N-ary scalar function for each N-tuple  of corresponding  
% values contained in its N inputs (e.g. scale by constant, max, Hadamard product, ...)   
%
% BinaryElementwiseUnit properties:
%  *funcHandle -  handle of the function to be applied to the input elements
%  *supportsArrays - does function implicitly support array input? [boolean] [false]
% 
% BinaryElementwiseUnit methods:
%   ElementwiseUnit(parent, ID, nInput, funcHandle, supportsArrays) - constructor
%   run() - execute processing
%
% Input ports:
%   #1 - vector/matrix of 1st function arguments
%   #2 - vector/matrix of 2nd function arguments (same dimensions as 1st)
%   [...]
%
% Output ports:
%   #1 - element-by-element function values (same dimension as each input):
%        OUT(k,l) = f(IN_1(k,l), ..., IN_N(k,l))
%
% See also: arrayfun

% Change log:
% 20/Apr/2017, PH - created
% 21/Jun/2017, PH - private set access to properties
classdef ElementwiseUnit < ProcUnit
    properties (SetAccess = private)
        funcHandle; % handle of the function to be applied to the input elements
        supportsArrays = false; % does function implicitly support array input?
    end
    
    methods
        function obj = ElementwiseUnit(parent, ID, nInput, funcHandle, supportsArrays)
            % obj = ElementwiseUnit(parent, ID, nInput, funcHandle [, supportsArray])
            %   nInput - number of input ports (= input dimensionality of function funcHandle) 
            %   funcHandle - handle of a (scalar, binary) function
            %   supportsArrays - does the function inherently perform
            %                    element-wise processing of array input?
            assert(isa(funcHandle, 'function_handle'), 'Argument funcHandle must be a function handle.')
            obj = obj@ProcUnit(parent, ID, nInput, 1);  % N in, 1 out
            obj.funcHandle = funcHandle;
        
            if nargin > 4
                obj.supportsArrays = supportsArrays;
            end
        end
        
        function run(obj)

            IN = arrayfun(@getData, obj.getInputUnit(1:obj.inputCount), 'UniformOut', false);
            
            if (obj.supportsArrays) % function can handle array inputs implicitly
                out = feval(obj.funcHandle, IN{:});
            else  % otherwise: explicit element-wise application
                out = arrayfun(obj.funcHandle, IN{:});
            end
            
            obj.setOutput(1, out);
        end
    end
end
