function [nlml] = nlmlGP(X,y,hyp)
l  = hyp(1);
sf = hyp(2);
sn = hyp(3);
n = length(X);

K = SEcov(X,X,[sf,l]) + eye(n).*sn.^2;
L = chol(K,'lower');
alpha = solve_chol(L',y);

nlml = -(-1/2*(y'*alpha) - sum(log(diag(L))) - n./2.*log(2*pi));
