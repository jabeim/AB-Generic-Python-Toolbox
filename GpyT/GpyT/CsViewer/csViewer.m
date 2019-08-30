% [hFig graph] = csViewer(CS [, hFig [, listen]])
%
% Create/update a strategy viewer window.
% NB: requires jgraphx.jar, GmtMxGraphFactory.class and
% GmtMxGraphFactory$1.class to be in the java classpath.
%
% INPUT:
%   CS - a CodingStrategy object
%   hFig - handle of a pre-existing strategy viewer to be updated (optional)
%   listen - create listener for changes in CS and enable automatic 
%            graph updates (0/1); default: 0
%
% OUTPUT:
%   hFig - handle of the figure created/updated
%   graph - internal graph representation of CS
%
% See also: initGmtClassPath.m
%
% Change log:
% Jun 2012, P.Hehrmann - created
% 08/12/2012, PH - bugfix: "listen" was being ignored for hFig ~= [];
%                   added documentation; 
% 19/12/2014, PH - adapted to new connection mechanism
% 19/08/2015, PH - minor change: edge x-offsets to reduce colocated vert. edges
% 21/Jun/2017, PH - different colors for modified and unmodified PUs
function [hFig, graph] = csViewer(CS, hFig, listen)

    persistent CS_listener;
    persistent graphComponent;
    persistent javaComponent;
    
    if nargin < 2 || isempty(hFig) || ~ishandle(hFig)
        hFig = figure('units','pixels','Toolbar','none');
        set(hFig,'Visible','on');  % force a window in MATLAB Live script
        newFigure = 1;
        graphComponent = [];
        
        hMenu = [];
        hMenu(end+1) = findall(hFig,'type','uimenu', 'tag', 'figMenuFile');
        hMenu(end+1) = findall(hFig,'type','uimenu', 'tag', 'figMenuEdit');
        hMenu(end+1) = findall(hFig,'type','uimenu', 'tag', 'figMenuWindow');
        hMenuUnwanted = setdiff(findall(hFig,'type','uimenu','parent', hFig), hMenu);
        delete(hMenuUnwanted);
        
    else
        newFigure = 0;
    end
    
    if nargin < 3
        listen = 1;
    end
    
    % set of line colors: hsv, avoiding blue and red. somehow.
    cols = hsv(36);
    cols = cols([5, 9, 11, 14, 17, 21, 28, 31],:) * 0.8;
    cols(3,:) = [0 0.5 0];
    
    % Drawing parameters:
    %   proc units
    %par.PU_varY = (cos(2*pi*(0:4)/5)+1)/2 * 24;
    par.PU_varY = [1.5 3 2 1 0] * 10;
    par.PU_varX = [0 10 20 10] * 0.0;

    par.edge_varX = [6 0 -6 -9 -3 3];
    
    par.PU_h = 78;
    par.PU_w = 55;
    par.PU_yOffs = par.PU_h+24;
    par.PU_xOffs = par.PU_w+45;
    par.PU_style = 'fillColor=#FFFFFF;strokeColor=#000000';
    par.PU_styleMod = 'fillColor=#A0A0A0;strokeColor=#000000';
    %   data units
    par.DU_h = 14;
    par.DU_w = 12;
    par.DU_yOffs = 18;
    par.DU_xOffs = 0;
    par.DU_yAnchIn = 5;
    par.DU_xAnchIn = -5 ;
    par.DU_yAnchOut = 5;
    par.DU_xAnchOut = par.PU_w - 5 ;

    par.DU_styleOut  = 'fillColor=#FFAAAA;strokeColor=#AA0000;verticalAlign=middle;verticalLabelPosition=middle;';
    par.DU_styleIn   = 'fillColor=#AAAAFF;strokeColor=#0000AA;verticalAlign=middle;verticalLabelPosition=middle;';
    par.DU_styleOutFull = [par.DU_styleOut,'strokeWidth=2'];
    par.DU_styleInFull = [par.DU_styleIn,'strokeWidth=2'];

    par.edgeStyle = 'edgeStyle=elbowEdgeStyle;orthogonal=1;elbow=horizontal;';

    graph = GmtMxGraphFactory.create();
    graph.setHtmlLabels(true);
    
    % Get the parent cell
    parent = graph.getDefaultParent();
    
    nPU = length(CS.procUnits);
    
    % Group update
    graph.getModel().beginUpdate();
    
    % number of ProcUnit at each depth level
    nAtDepth = zeros(1,nPU);
    
    iConAtDepth = zeros(1,nPU);
    
    % number of connections within strategy
    nConTot = 0;

    for iPU = 1:nPU
        PU = CS.procUnits{iPU};

        xNew = par.PU_w/2 + par.PU_xOffs * PU.depth + par.PU_varX(mod(nAtDepth(PU.depth+1),length(par.PU_varX))+1);
        yNew = par.PU_h/2 + par.PU_yOffs * nAtDepth(PU.depth+1) + par.PU_varY(mod(PU.depth,length(par.PU_varY))+1);
        nAtDepth(PU.depth+1) = nAtDepth(PU.depth+1) + 1;
             
        % add PU box
        if ~PU.modified 
            v{iPU}.PU = graph.insertVertex(parent, PU.ID, PU.ID, xNew, yNew, par.PU_w, par.PU_h, par.PU_style); %#ok<AGROW>
        else
            v{iPU}.PU = graph.insertVertex(parent, PU.ID, PU.ID, xNew, yNew, par.PU_w, par.PU_h, par.PU_styleMod); %#ok<AGROW>
        end
        
        nDUin = PU.inputCount;
        nDUout = PU.outputCount;
        
        v{iPU}.DuIn = cell(1,nDUin); %#ok<AGROW>
        v{iPU}.DuOut = cell(1,nDUout); %#ok<AGROW>
        
        xDuNext = par.DU_xAnchIn + xNew;
        yDuNext = par.DU_yAnchIn + yNew;
        
        % add input DUs
        for iDU = 1:nDUin
            DU = PU.getInputUnit(iDU);
            nConTot = nConTot + DU.getNumberConnections();
            
            if DU.dataIsEmpty()
                style = par.DU_styleIn;
            else
                style = par.DU_styleInFull;
            end
            v{iPU}.DuIn{iDU} = graph.insertVertex(parent, DU.ID, sprintf('%d',iDU), xDuNext, yDuNext, par.DU_w, par.DU_h, style);
            xDuNext = xDuNext + par.DU_xOffs;
            yDuNext = yDuNext + par.DU_yOffs;
        end
        
        xDuNext = par.DU_xAnchOut + xNew;
        yDuNext = par.DU_yAnchOut + yNew;
        % add output DUs
        for iDU = 1:nDUout
            DU = PU.getOutputUnit(iDU);
            
            
            if DU.dataIsEmpty()
                style = par.DU_styleOut;
            else
                style = par.DU_styleOutFull;
            end
            v{iPU}.DuOut{iDU} = graph.insertVertex(parent, DU.ID, sprintf('%d',iDU), xDuNext, yDuNext, par.DU_w, par.DU_h, style);
            xDuNext = xDuNext + par.DU_xOffs;
            yDuNext = yDuNext + par.DU_yOffs;
        end
    end
    
    % add connections
    edges = cell(1,nConTot);
    edgeOffsets = zeros(1,nConTot);
    
    iConTot = 0;
    iDuOutTot = 0;
    
    for iPU = 1:nPU
        srcPU = CS.procUnits{iPU};
        for iDU = 1:length(v{iPU}.DuOut)
            srcVert = v{iPU}.DuOut{iDU};
            srcDU = CS.procUnits{iPU}.getOutputUnit(iDU);
            
            nConOut = length(srcDU.connection);

            if (nConOut > 0) 
                iDuOutTot = iDuOutTot+1; % current count of connected output DUs visited in total
            end
            
            indCol = mod((iDuOutTot-1),size(cols,1))+1; % index into color array            
            
            srcTxt = cell(1,nConOut);
            iConAtDepth(srcPU.depth+1) = iConAtDepth(srcPU.depth+1) + 1;
            
            for iConOut = 1:nConOut
                iConTot = iConTot+1;
                destPU = srcDU.connection(iConOut).destUnit;
                iDestPU = srcDU.connection(iConOut).destUnitIndex;
                iDestDU = srcDU.connection(iConOut).destPortIndex;
                destDU = srcDU.connection(iConOut).destPort;
                
                destVert = v{iDestPU}.DuIn{iDestDU};

                eStyle = [par.edgeStyle, 'strokeColor=', col2str(cols(indCol,:))];

                E = graph.insertEdge(srcVert, '', '', srcVert, destVert, eStyle);                

                srcTxt{iConOut+1} = sprintf('-> %s:%d<br>',destPU.ID,iDestDU);
                destVert.setId(sprintf('<- %s:%d',srcPU.ID,iDU));
                E.setId(sprintf('%s:%d -> %s:%d',srcPU.ID,iDU,destPU.ID,iDestDU))
                
                edges{iConTot} = E;                
                
                %edgeOffsets(iConTot) = par.edge_varX(mod(iDuOutTot-1, length(par.edge_varX))+1);
                edgeOffsets(iConTot) = par.edge_varX(mod(iConAtDepth(srcPU.depth+1)-1, length(par.edge_varX))+1);
            end
            srcVert.setId(sprintf('%s', '<html>', srcTxt{:}, '</html>'));
        end
    end


                
    graph.getModel().endUpdate();  
    graph.setCellsLocked(0);    
    
    graph.getModel().beginUpdate();  
    for iCon = 1:nConTot
        points = graph.getView().getState(edges{iCon}).getAbsolutePoints();
        x = points.get(1).getX;
        x = x + edgeOffsets(iCon);
        points.get(1).setX(x);
        points.get(2).setX(x);
    end
    graph.getModel().endUpdate();
    
    if ~isempty(graphComponent)
        vertScrollPos = graphComponent.getVerticalScrollBar.getValue();
        horizScrollPos = graphComponent.getHorizontalScrollBar.getValue();
    else
        vertScrollPos = 0;
        horizScrollPos = 0;
    end
    
    % Get scrollpane
    graphComponent = com.mxgraph.swing.mxGraphComponent(graph);
    graphComponent.setToolTips(1);
    graphComponent.setConnectable(0);
  
    % determine figure size (auto if new, same as before otherwise)
        screenSize = get(0,'ScreenSize');
        graphSize = [0, 0, graphComponent.getPreferredSize().width,graphComponent.getPreferredSize().height];        
        pos = min(screenSize, graphSize + [0 0 par.PU_w/4 par.PU_h/4]);
    if newFigure
        pos(1:2) = round(screenSize(3:4)/2 - pos(3:4)/2);        
    else
        posOld = get(hFig,'position');
        pos(1:2) = posOld(1:2);
    end
        set(hFig,'Position',pos);
    
    % create JPanel that holds the graph
    graphPanel = javax.swing.JPanel(java.awt.BorderLayout);
    graphPanel.add(graphComponent);    
        
    % Create new matlab container hold graphPanel...
    if newFigure
        [javaComponent, hcontainer] = javacomponent(graphPanel, [0,0,pos(3:4)], hFig);
        set(hFig,'ResizeFcn',{@csViewer_resizeFcn, hcontainer});
        % maintain only one "active" view in case of multiple calls to csViewer
        if (~isempty(CS_listener))
           delete(CS_listener);
        end
        % register GraphChanged-listener in CS:
        if listen
            CS_listener = addlistener(CS, 'GraphChanged', @(src, data) csViewer(CS, hFig));
        else
            CS_listener = [];
        end
        % ensure removal of listener when figure is closed
        set(hFig,'DeleteFcn',@(src, event) delete(CS_listener));
    
    else % or replace old graphPanel inside existing container
        
        javaComponent.removeAll();
        javaComponent.add(graphPanel);
        javaComponent.updateUI();
        
        % create / delete listener for graph changes as requested
        if listen % online updates requested
            if isempty(CS_listener) % no listener exists: create one
                CS_listener = addlistener(CS, 'GraphChanged', @(src, data) csViewer(CS, hFig));
            end
        else % no online updates requested
            if ~isempty(CS_listener) % change listener exists: delete 
                delete(CS_listener);
                CS_listener = [];
            end
        end        
        
    end
    
    % set scroll positions as before
    graphComponent.getVerticalScrollBar.setValue(vertScrollPos);
    graphComponent.getHorizontalScrollBar.setValue(horizScrollPos);

end

function str = col2str(col)

str = dec2hex(round(col*255))';
str = ['#', str(:)'];

end