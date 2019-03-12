function [indi_init] = initSampling(method,windowSize,N_inducing)
%INITSAMPLING Initial selection of inducing points (by indices)
%
% Input arguments:  'N_inducing'   - Number of inducing points
%                   'windowSize'   - Total size of floating frame
%                   'method'       - To indicate which method rule is used
%
% Output arguments: 'indi_init'    - Vector with indices; inducing_points = X(indi_init,:)
%
% Syntax:       initSampling(1,Z,M)
%               initSampling(2,200,25)
%
% Author: W. van Dijk
% Date: (v1)    5-3-2019: Create function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch method
    case 1          %Eqidistant
        indi_init = round(linspace(1,windowSize,N_inducing));
    otherwise       %Random
        indi_init = [sort(randi(windowSize,1,N_inducing)), windowSize];
end
end