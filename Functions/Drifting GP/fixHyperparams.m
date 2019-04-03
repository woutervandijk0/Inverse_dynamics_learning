function [inf] = fixHyperparams(ell,inf,param_fix)

% Prior distributions - Exlude some hyperparams from optimization
prior.cov = {};
prior.cov{length(ell),1} = [];
for jj = param_fix
    prior.cov{jj} = {@priorDelta};      % @priorDelta fixes the jj'th hyperparam in hyp.cov
end
inf       =  {@infPrior,inf,prior};     % Add prior to inference method
