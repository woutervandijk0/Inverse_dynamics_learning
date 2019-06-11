function [LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs,...
    Dff,LD,Kbb] = sgpBuildTerms(hyp,sn,f,yf,b,s,alpha);

jitter = 1e-4;
Mb = length(b);

Kff     = SEcov(f,f,hyp);
Kfdiag  = diag(Kff);
Kbf     = SEcov(b,f,hyp);
Kbb     = SEcov(b,b,hyp) + eye(Mb)*jitter;

Lb          = chol(Kbb,'lower');
Lbinv_Kbf   = solve_lowerTriangular(Lb,Kbf);

Qfdiag      = Kfdiag - diag(Lbinv_Kbf'*Lbinv_Kbf);
%Qfdiag      = Kfdiag' - sum(Lbinv_Kbf.^2);
Dff         = sn + alpha.*Qfdiag;
Lbinv_Kbf_LDff = Lbinv_Kbf./sqrt(Dff');

D = eye(Mb) + Lbinv_Kbf_LDff*Lbinv_Kbf_LDff';
LD = chol(D,'lower');

Kbs         = SEcov(b,s,hyp);
Lbinv_Kbs   = solve_lowerTriangular(Lb, Kbs);

LDinv_Lbinv_Kbs = solve_lowerTriangular(LD, Lbinv_Kbs);
LDinv_Lbinv_Kbf = solve_lowerTriangular(LD,Lbinv_Kbf);

Sinv_y          = (yf./Dff')';
c               = Lbinv_Kbf*Sinv_y;
%LDinv_Lbinv_Kbf_c  = LDinv_Lbinv_Kbf*Sinv_y;
LDinv_c         = solve_lowerTriangular(LD,c);
