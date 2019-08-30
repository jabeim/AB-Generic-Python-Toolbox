% Script to explicitly add the relevant directories from the GMT into the
% MATLAB path to avoid namespace collisions
%
% The environment variable GMTROOT needs to be set.
%
% 28.05.2018 Joachim Thiemann created
global GMTROOT

if isempty(GMTROOT)
    GMTROOT = getenv('GMTROOT');
    if isempty(GMTROOT)
        error('Environment variable GMTROOT needs to be set!');
    end
end

addpath([GMTROOT, filesep, 'Utility'])
initGmtClassPath;

% Adding enough of the path to run the demos
addpath([GMTROOT, filesep, 'Agc']);
addpath([GMTROOT, filesep, 'Clearvoice']);
addpath([GMTROOT, filesep, 'CsViewer']);
addpath([GMTROOT, filesep, 'Demo']);
addpath([GMTROOT, filesep, 'Filterbank']);
addpath([GMTROOT, filesep, 'Framework']);
addpath([GMTROOT, filesep, 'Frontend']);
addpath([GMTROOT, filesep, 'Generators']);
addpath([GMTROOT, filesep, 'Mapping']);
addpath([GMTROOT, filesep, 'Mixer']);
addpath([GMTROOT, filesep, 'Plotting']);
addpath([GMTROOT, filesep, 'PostFilterbank']);
addpath([GMTROOT, filesep, 'Strategies'])
addpath([GMTROOT, filesep, 'Synthesis']);
addpath([GMTROOT, filesep, 'Vocoder']);
addpath([GMTROOT, filesep, 'WinBuf']);