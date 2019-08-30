function csViewer_resizeFcn(src, event, container)
    pos = get(gcbo,'Position');
    set(container,'Position',[0 0 pos(3:4)]);       
    
end