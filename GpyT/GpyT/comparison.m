
clear all
close all 
matData = load('GMTresults.mat');
pyData = load('GpyTdataPYTHON.mat');


varList = fields(pyData);

for i = 1:length(varList)-3
    if isstruct(matData.(varList{i}))
    else
        if size(matData.(varList{i}),2) == 1
            matData.(varList{i}) = matData.(varList{i})';
        end
        if size(pyData.(varList{i}),2) == 1
            pyData.(varList{i}) = pyData.(varList{i})';
        end
        
        
        pyComp.(varList{i}) = double(pyData.(varList{i}))-matData.(varList{i});
        deviation(i,:) = [sum(sum(abs(pyComp.(varList{i})))) sum(sum(abs(pyComp.(varList{i}))))/prod(size(pyComp.(varList{i})))];
        disp([varList{i} ':' num2str(deviation(i,1)) '(' num2str(deviation(i,2)) ')' ])
        if size(pyComp.(varList{i}),1) == 1 && sum(pyComp.(varList{i})) ~= 0
            figure('Name',varList{i})
            hold on
            plot(matData.(varList{i}),'r--')
            plot(pyData.(varList{i}),'b:')
            plot(pyComp.(varList{i}),'k')
            hold off
        elseif size(pyComp.(varList{i}),1) > 1 && size(pyComp.(varList{i}),1) <= 16 && sum(sum(pyComp.(varList{i}))) ~= 0
            figure('Name',varList{i})
            plots = size(pyComp.(varList{i}),1);
            
            for ii = 1:plots
                subplot(5,1,[1 4])
                
                
%                 plot(find(diff(matData.(varList{i})(ii,:))~=0),matData.(varList{i})(ii,diff(matData.(varList{i})(ii,:))~=0)/max(max(abs(matData.(varList{i}))))+(ii),'r--')
%                 if ii == 1; hold on; end
%                 plot(find(diff(pyData.(varList{i})(ii,:))~=0),pyData.(varList{i})(ii,diff(pyData.(varList{i})(ii,:))~=0)/max(max(abs(pyData.(varList{i}))))+(ii),'b:')
%                 plot(find(diff(pyComp.(varList{i})(ii,:))~=0),pyComp.(varList{i})(ii,diff(pyComp.(varList{i})(ii,:))~=0)/max(max(abs(pyComp.(varList{i}))))+(ii),'k')
%                 if ii == plots; hold off; end
                
                plot(matData.(varList{i})(ii,:)/max(max(abs(matData.(varList{i}))))+(ii),'r--')
                if ii == 1; hold on; end
                plot(pyData.(varList{i})(ii,:)/max(max(abs(matData.(varList{i}))))+(ii),'b:')
                plot(pyComp.(varList{i})(ii,:)/max(max(abs(matData.(varList{i}))))+(ii),'k')
                if ii == plots; hold off; end
                
                
                
                subplot(5,1,5)
                plot(pyComp.(varList{i})(ii,:))
                
                if ii == 1; hold on; elseif ii == plots; hold off; end
            end
            

        elseif sum(sum(pyComp.(varList{i}))) == 0
%             disp(['Match: ' varList{i}])
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