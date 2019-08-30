% function generateProcUnitFromTemplate(procUnitName, saveDir, withFunc)
%
% Input:
%   procUnitName - class name of new ProcUnit, NOT including the "[...]Unit" suffix
%   saveDir - sub-folder of GMTROOT where new ProcUnit will be created
%   withFunc - create corresponding function for ProcUnit? 0/1
%

% Change log:
% 2012, MM - generated
% 27 Jun 2017, PH - add placeholder "PROCFUNCNAME"
function generateProcUnitFromTemplate(procUnitName, saveDir, withFunc)

if nargin ~= 3
    help(mfilename);
    return;
end

if isempty(getenv('GMTROOT'))
    error('Please define environmental variable GMTROOT.');
end

dirRoot = fullfile(getenv('GMTROOT'), 'Templates');

fidTmp = fopen(fullfile(dirRoot, '__ProcUnitTemplate__.m'));
lines = {};
procUnitName(1) = upper(procUnitName(1));

if isempty(strfind(procUnitName, 'unit')) || isempty(strfind(procUnitName, 'Unit'))
    procUnitName = strcat(procUnitName, 'Unit');
end

while ~feof(fidTmp)
   lines{end + 1} = fgetl(fidTmp); 
end
fclose(fidTmp);

destPath = fullfile(getenv('GMTROOT'), saveDir);
if ~exist(destPath,'dir')
    fprintf('Creating folder %s\n', destPath);
    mkdir(destPath);
end

destFile = fullfile(getenv('GMTROOT'), saveDir, [procUnitName '.m']);
if exist(destFile, 'file')
   error('%s already exists.\n', destFile); 
end

if withFunc

    procFunc = strrep(procUnitName, 'Unit', 'Func');
    procFunc(1) = lower(procFunc(1));    
    destFuncFile = fullfile(getenv('GMTROOT'), saveDir, ...
        [procFunc '.m']);
    if exist(destFuncFile, 'file')
        error('%s already exists.\n', destFuncFile);
    end
    fprintf('Creating file %s\n', destFuncFile);
    fidFunc = fopen(destFuncFile, 'wt');
    fprintf(fidFunc, ['function ' procFunc '(par, x)\n']);
    fclose(fidFunc);
    procFuncCall = strcat('y = ', procFunc, '(obj, x)');
else
    procFunc = '';
    procFuncCall = '';
end

fprintf('Creating file %s\n', destFile)
fid = fopen(destFile, 'wt');
L = length(lines);

for i = 1:L
    lines{i} = strrep(lines{i}, 'PROCUNITCLASSNAME', procUnitName);
    lines{i} = strrep(lines{i}, 'PROCFUNCCALL', procFuncCall);
    lines{i} = strrep(lines{i}, 'PROCFUNCNAME', procFunc);
    fprintf(fid, '%s\n', lines{i});
end
fclose(fid);
disp('Done.');
