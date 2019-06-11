function [m,var,Su] = predictOSGP(hyp,b,s,Lb,LD,LDinv_c,Kbs)
lowtriang   = dsp.LowerTriangularSolver;
lowtriang.release();

jitter = 1e-8;

Kbs = SEcov(b,s,hyp);
Lbinv_Kbs = lowtriang(Lb, Kbs);
lowtriang.release();
LDinv_Lbinv_Kbs = lowtriang(LD, Lbinv_Kbs);
lowtriang.release();

%Predictive mean
m = LDinv_Lbinv_Kbs'*LDinv_c;

Ms = length(s);
%Prediction variance (matrix)
Kss = SEcov(s,s,hyp) + eye(Ms)*jitter;
var1 = Kss;
var2 = -Lbinv_Kbs'*Lbinv_Kbs;
var3 = LDinv_Lbinv_Kbs'*LDinv_Lbinv_Kbs;
Su  = var1 + var2 + var3;

%Prediction variance (vector)
var = diag(Su);