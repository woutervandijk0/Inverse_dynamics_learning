function [m,var,Su] = predictOSGP(hyp,b,s,Lb,LD,LDinv_c,Kbs)
jitter = 1e-8;

%Kbs = SEcov(b,s,hyp);
Lbinv_Kbs       = solve_lowerTriangular(Lb, Kbs);
LDinv_Lbinv_Kbs = solve_lowerTriangular(LD, Lbinv_Kbs);

%Predictive mean
m = LDinv_Lbinv_Kbs'*LDinv_c;

Ms = size(s,1);
%Prediction variance (matrix)
Kss = SEcov(s,s,hyp) + eye(Ms)*jitter;
var1 = Kss;
var2 = -Lbinv_Kbs'*Lbinv_Kbs;
var3 = LDinv_Lbinv_Kbs'*LDinv_Lbinv_Kbs;
Su  = var1 + var2 + var3;

%Prediction variance (vector)
var = diag(Su);