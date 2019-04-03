function [xu,indi_update] = updateInducingPoints(Z_cur,X_cur,indi,forgetRate,batchSize,windowSize,method)
%UPDATEINDUCINGPOINTS updates the inducing points in the moving window.
% four update methods are available (4 is recommended)
%
% Input arguments:  'Z_cur' - Current inducing points
%                   'X_cur' - Input data of current window
%                   'indi'  - indices of inducing points of the current
%                             window
%                   'forgetRate'   - Factor with which samples are
%                                    forgotten (see 'case 4')
%                   'batchSize'    - Data arrives in batches of 'batchSize'
%                   'windowSize'   - Total size of floating frame
%                   'method'       - To indicate which update rule is used
%
% Output arguments: 'errorMeasure' - scalar/vector containing the error
%                                    measure
%
% Syntax:       updateInducingPoints(Z_cur,X_cur,indi,forgetRate,batchSize,method)
%               updateInducingPoints(Z_cur,X_cur,indi,0.1,10,4)
%
% Author: W. van Dijk
% Date: (v1)    5-3-2019: Create function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch method
    case 1          %Eqidistant
        xu = X_cur(indi,:);
    case 2          %Random
        % update inducing points
        indi  = indi - batchSize;
        indi_r = size(find(indi<1),2);
        indi_update = [indi(indi_r+1:end),windowSize+indi(1:indi_r)];
        xu = X_cur(indi_update,:);
    case 3
        indi  = [indi(1:(end-1))-batchSize, indi(end)];
        indi_r = size(find(indi<1),2);
        if indi_r > 0
            indi(end)= indi(end) - batchSize;
            indi_update = [indi(indi_r+1:end),windowSize+indi(1:indi_r-1),windowSize];
        else
            indi_update = indi;
        end
        xu = X_cur(indi_update,:);
    case 4
        if (forgetRate > 1) || (forgetRate <0)
            forgetRate = 0.7;
            disp('Warning: forgetRate must be picked between 0 and 1...')
            disp('Warning: forgetRate is set to 0.7...')
        end
        M = size(Z_cur,1);
        M_old = floor(M*forgetRate);
        M_new = M-M_old;
        Z_old = Z_cur(sort(randi(M,M_old,1)),:);
        Z_new = X_cur([sort(randi(size(X_cur,1),M_new-1,1));size(X_cur,1)],:);
        xu = [Z_old;Z_new];
        indi_update = [];
        
end
end