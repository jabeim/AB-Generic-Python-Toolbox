% Add GMT-specific entries to the dynamic java classpath.
% The GMT base directory is read from environment variable 'GMTROOT'.
%
% ! NB: Global variables MUST be re-declared in all workspaces except the
% base and caller workspace after calling initGmtClassPath, even though 
% their values will be preserved. The values do not need to be 
% reassigned after redeclaration. initGmtClassPath uses Matlab's javaaddpath,
% which by itself clears all global variables as a side effect. initGmtClassPath 
% tries to save and restore global variables and breakpoints to avoid 
% unwanted side-effects as far as possible. initGmtClassPath will not call 
% javaaddpath if the required directories are already in the classpath. 
%
% It is recommended to call initGmtClassPath before the declaration of global variables.
%
% See also: javaaddpath, clear
%
% Change log:
% 08 Dec 2012, P.Hehrmann - created
% 20 Dec 2012, PH - protect global variables 
function initGmtClassPath

jPath___ = javaclasspath('-all');
gmtBasePath___ = getenv('GMTROOT');
gmtPath___ = {fullfile(gmtBasePath___, 'CsViewer'), fullfile(gmtBasePath___, 'CsViewer', 'jgraphx.jar')};

% check if gmtPath needs to be added at all
needsAdding___ = ~all( cellfun(@(x) any( strcmp(x,jPath___)), gmtPath___) );

if  needsAdding___

    % get all global vars and breakpoints
    gPre___ = who('global');
    dbtmp___ = dbstatus('-completenames');
    
    
    gVisibleBase = evalin('base','whos');
    gVisibleBase = {gVisibleBase(arrayfun(@(x) getfield(x,'global'), gVisibleBase)).name};
    
    gVisibleCaller = evalin('caller','whos');
    gVisibleCaller = {gVisibleCaller(arrayfun(@(x) getfield(x,'global'), gVisibleCaller)).name};

    try 

        if ~isempty(gPre___)
            eval(sprintf('global %s;', sprintf('%s ', gPre___{:})));
        end
        
        % create local copies of global variables
        for iVar = 1:length(gPre___)
            eval(sprintf('local_%s = %s;', gPre___{iVar}, gPre___{iVar}));
        end
  
        javaaddpath(gmtPath___);
        pause(0.1);

        % restore global variables from local copies
        for iVar = 1:length(gPre___)
            eval(sprintf('global %s;',  gPre___{iVar}));
            eval(sprintf('%s = local_%s;', gPre___{iVar}, gPre___{iVar}));
        end
        
        if ~isempty(gVisibleBase)
            evalin('base', ['global ' sprintf('%s ', gVisibleBase{:})] );
        end
        if ~isempty(gVisibleCaller)
            evalin('caller', ['global ' sprintf('%s ', gVisibleCaller{:})] );
        end

    catch ex
        disp(ex.getReport('basic', 'hyperlinks', 'on'));
        javaaddpath(gmtPath___);
    end
    
    dbstop(dbtmp___);
    
    % check if all globals have been restored
    gPost___ = who('global');
    beenRestored___ = cellfun(@(x) any(strcmp(x, gPost___)), gPre___);   
    allRestored___ = all(beenRestored___);
    
    if ~allRestored___        
        warning('The following global variable(s) could not be preserved:\n   %s', sprintf('%s  ', gPre___{~beenRestored___}));
    end
    
end