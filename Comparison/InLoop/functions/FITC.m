function [mu_s, var_s, mu_u, var_u, Kuu] = FITC(hyp,sn,u,f,yf,s)
%FITC offline FITC algortihm

sn2 = sn.^2;
Mu  = length(u);
Mf  = length(f);
Kuu = SEcov(u,u,hyp) + eye(Mu)*sn2;
Kuf = SEcov(u,f,hyp);
Kfu = SEcov(f,u,hyp);
Kus = SEcov(u,s,hyp);
Kss = SEcov(s,s,hyp);
Kff = SEcov(f,f,hyp) + eye(Mf)*sn2;

%Equation 8
Lu  = chol(Kuu,'lower');
Luinv_Kuf = solve_lowerTriangular(Lu,Kuf);
Qff = Luinv_Kuf'*Luinv_Kuf;

%equation 20 & 21
Lambda_ff = diag(Kff - Qff);
Kff_hat   = Qff + diag(Lambda_ff);

%Equation 27 (zero mean)
B  = Kuu + Kuf*diag(1./Lambda_ff)*Kuf';
%Binv  = inv(B);
%var_u = Kuu*Binv*Kuu
LB = chol(B,'lower');
LBinv_Kuu = solve_lowerTriangular(LB,Kuu);
var_u = LBinv_Kuu'*LBinv_Kuu;

%Equation 26 (zero mean)
Luinv_var_u = solve_lowerTriangular(Lu,var_u');
Kuf_Lambda_ffinv_f = Kuf*diag(1./Lambda_ff)*yf;
Luinv_Kuf_Lambda_ffinv_f = solve_lowerTriangular(Lu,Kuf_Lambda_ffinv_f);
mu_u = 0 + Luinv_var_u'*Luinv_Kuf_Lambda_ffinv_f;

% Prediction
%Equation 28 
Luinv_Kus = solve_lowerTriangular(Lu,Kus);
Luinv_mu_u = solve_lowerTriangular(Lu,mu_u);
mu_s = Luinv_Kus'*Luinv_mu_u;

%Equation 29 
D = Kuu - var_u;
Luinv_D = solve_lowerTriangular(Lu,D);
Kuuinv_Kus = solve_linSystem(Kuu,Kus);
var_s = Kss - Luinv_Kus'*Luinv_D*Kuuinv_Kus;

end

