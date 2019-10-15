
clear all
matData = load('GMTresults.mat')
pyData = load('GpyTdata.mat')


varList = fields(pyData);

for i = 1:length(varList)-2
    if isstruct(matData.(varList{i}))
    else
        if size(matData.(varList{i}),2) == 1
            disp(varList{i})
            matData.(varList{i}) = matData.(varList{i})';
        else
        end

        pyComp.(varList{i}) = double(pyData.(varList{i}))-matData.(varList{i});

        if size(pyComp.(varList{i}),1) == 1 && sum(pyComp.(varList{i})) ~= 0
            figure('Name',varList{i})

            hold on
            plot(matData.(varList{i}),'r--')
            plot(pyData.(varList{i}),'b:')
            plot(pyComp.(varList{i}),'k')

            hold off
        end
    end
    
end


agcList = fields(pyData.agc);

for i = 1:length(agcList)
    pyComp.(agcList{i}) = pyData.agc.(agcList{i})-matData.agc.(agcList{i});
    
    figure('Name',agcList{i})
    hold on
    plot(matData.agc.(agcList{i}),'r--')
    plot(pyData.agc.(agcList{i}),'b:')
    plot(pyComp.(agcList{i}),'k')
    hold off
end