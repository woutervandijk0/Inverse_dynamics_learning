function [mu_s,var_s,mu_u,var_u] = IncrementalFITC(hyp,sn,u,s,fp,yfp,mu_u,var_u,Lu,Kuu)
%INCREMENTALFITC Incremental version of FITC
%   Detailed explanation goes here
sn2 = sn.^2;

Mf = size(fp,1);
Mu = size(u,1);
Ms = size(s,1);

Kfpfp = SEcov(fp,fp,hyp) + eye(Mf)*sn2;
Kufp  = SEcov(u,fp,hyp);
Kss   = SEcov(s,s,hyp) + eye(Ms)*sn2;
Kus   = SEcov(u,s,hyp);

%Equation 8
Luinv_Kufp = solve_lowerTriangular(Lu,Kufp);
Qfpfp = Luinv_Kufp'*Luinv_Kufp;
Lambda_fpfp = diag(Kfpfp - Qfpfp);

%Equation 44b
%LuTinv_Kufp_Luinv = solve_lowerTriangular(Lu',Luinv_Kufp);
Kuuinv_Kufp = Kuu\Kufp;
Pnp = (Lambda_fpfp.^-1).*Kuuinv_Kufp*Kuuinv_Kufp';
%Pnp = (Lambda_fpfp.^-1).*inv(Lu)'*Luinv_Kufp*Luinv_Kufp'*inv(Lu);

%Equation 45
var_up = var_u - (var_u*Pnp*var_u)/(1+trace(var_u*Pnp));

%Equation 47
Luinv_var_upT = solve_lowerTriangular(Lu,var_up');
mu_up = (eye(Mu) - var_u*Pnp/(1+trace(var_u*Pnp)))*mu_u + (Lambda_fpfp^-1)*Luinv_var_upT'*Luinv_Kufp*yfp;

%Prediction
%Equation 28
Luinv_Kus = solve_lowerTriangular(Lu,Kus);
Luinv_mu_up = solve_lowerTriangular(Lu,mu_up);
mu_sp = Luinv_Kus'*Luinv_mu_up;

%Equation 29
%Kus   = SEcov(u,s,hyp);
D = Kuu - var_u;
Luinv_D = solve_lowerTriangular(Lu,D);
Kuuinv_Kus = solve_linSystem(Kuu,Kus);
var_sp = Kss - Luinv_Kus'*Luinv_D*Kuuinv_Kus;

mu_u = mu_up;
var_u = var_up;

mu_s  = mu_sp;
var_s = var_sp;

end

