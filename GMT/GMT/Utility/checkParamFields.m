% function checkParamFields(param, requiredFields)
% Check whether a number of required fields are contained in parameter
% struct or object. Throws an error if required fields are missing.
%
% INPUT:
%    param - struct or object
%    requiredFields - cell array of strings containing required field names
% 
% Change log:
% Apr. 2012, M.Milczynki - created
% 30/04/2012, P.Hehrmann - added support for objects
function ok = checkParamFields(param, requiredFields)

if (isstruct(param))    % param is a struct
    for j = 1:length(requiredFields)
        if ~isfield(param, requiredFields{j})
            error('Wrong parameter names or paramter missing.');
        end
    end
    
elseif (isobject(param)) % param is an object
    for j = 1:length(requiredFields)  % attempt to access all required fields: throws error if not possible
        foo = param.(requiredFields{j});
    end
    
else % param is something different
    error('Argument ''param'' needs to be either a struct or an object.');
end

ok = 1;