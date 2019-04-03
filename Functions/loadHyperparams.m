function [sn, sf, ell]= loadHyperparams(dataID,isRecurrent)
folderName = 'Results\hyperparamSettings\';
dataID     = dataID(1:end-4);
if isRecurrent == true
    extensionStr = '_recurrent_param.mat';
else
    extensionStr = '_param.mat';
end

load([folderName,dataID,extensionStr]);






