function [errorMeasure] = errorMeasure(goal,est,varargin)
%ERRORMEASURE Calculate the error with a (normalized) error measure
% This function calculates a measure of the error between the true ('goal') data and the estimated ('est') data.         
%
% Input arguments:  'goal'   - vector/matrix containing true data
%                   'est'    - vector/matrix containing estimated data
%                   'method' - (string) defines the error measure. Default
%                              is NMSE (others: MAE)
%                   'show'   - show the error measure in command window
%
% Output arguments: 'errorMeasure' - scalar/vector containing the error
%                                    measure
%
% Syntax:       errorMeasure(X,X_est)
%               errorMeasure(X,X_est,'method','MAE','show',true)
%
% Author: W. van Dijk
% Date: (v1)    4-3-2019: Create function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input Parser
defaultFig      = false;
defaultMethod   = 'NMSE';
expectedMethods = {'NMSE',...
                   'MAE',...
                   };
p = inputParser;
addRequired(p,'goal',@(x) size(size(x),2)<3);
addRequired(p,'est',@(x) size(size(x),2)<3);
addOptional(p,'show',defaultFig,@islogical);
addOptional(p,'method',defaultMethod,...
    @(x) any(validatestring(x,expectedMethods)));
parse(p,goal,est,varargin{:});
method = p.Results.method;

%% Check and compare dimensions of input
[nG mG] = size(goal);
[nE mE] = size(est);
if nG ~=nE
    error('The dimensions of "goal" and "est" do not match...')
elseif mG ~= mE
    error('The dimensions of "goal" and "est" do not match...')
end

%% Transpose input vectors/matrices if necessary
if nG < mG 
    goal =  goal';
    est  =  est';
    L    =  mG;
else 
    L = nG;
end

%% Calculate error measure with a given method
switch method
    case 'NMSE'     % Normalized Mean Square Error
        errorMeasure = sum((goal-est).^2)./(mean(goal).*mean(est))/L;
    case 'MAE'      % Mean Absolute Error
        errorMeasure = sum(abs(goal-est))/L;
end
%% Print result
if p.Results.show == true
    str = [method,':   ', num2str(errorMeasure)];
    disp(str);
end

return
end

