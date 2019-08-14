function [bound] = sgpNLML(hyp,alpha,f,yf,b,s,err,Mf)
sn = abs(hyp(end));
hyp = abs(hyp(1:end-1));
[~, LDinv_c, ~, Dff, LD, ~] = sgpBuildTerms(hyp,sn,f,yf,b,s,alpha);
bound = 0;
% constant term
bound = - 0.5*Mf*log(2*pi);
% quadratic term
bound = bound - 0.5 * sum(err'.^2./Dff');
bound = bound + 0.5 * sum(LDinv_c.^2);

% log det term
bound = bound - 0.5 * sum(log(Dff));
bound = bound - sum(log(diag(LD)));

% trace-like term
bound = bound - 0.5*(1-alpha)/alpha * sum(log(Dff./sn));
bound = -bound;