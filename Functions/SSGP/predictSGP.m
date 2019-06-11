function [m,var,Su] = predictSGP(hyp, s, LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs)
jitter = 1e-4;
Ms = length(s);

%Predictive mean
m = LDinv_Lbinv_Kbs'*LDinv_c;

%Prediction variance (matrix)
Kss  = SEcov(s,s,hyp) + eye(Ms)*jitter;
var1 = Kss;
var2 = -Lbinv_Kbs'*Lbinv_Kbs;
var3 = LDinv_Lbinv_Kbs'*LDinv_Lbinv_Kbs;
Su   = var1 + var2 + var3;

%Prediction variance (vector)
var  = diag(Su);