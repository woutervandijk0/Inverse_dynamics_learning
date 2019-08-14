function [bound] = osgpNLML(hyp,sn,alpha,f,yf,a,b,Saa,ma,Kaa_old,err)
%hyp = abs(hyp(1:end-1));
%sn = abs(hyp(end));

 hyp = abs(hyp);
 sn  = abs(sn);

Mf = length(f);
[La, Lb, LD, LSa, LDinv_c, Dff, Sainv_ma, LM, Q, LQ] = osgpBuildTerms(hyp,sn,f,yf,a,b,Saa,ma,Kaa_old,alpha);

Lainv_ma = solve_lowerTriangular(LSa, ma);

bound = 0;
%constant term
bound = -0.5*Mf*log(2*pi);
%quadratic term
bound = bound - 0.5 * sum(err.^2./Dff');
bound = bound - 0.5 * sum(Lainv_ma.^2);
bound = bound + 0.5 * sum(LDinv_c.^2);

ma_Sainv_LM = Sainv_ma'*LM;
Qinv_LM_Sainv_ma = Q/ma_Sainv_LM;
bound = bound + 0.5 * alpha * sum(ma_Sainv_LM*Qinv_LM_Sainv_ma);

%log det term
bound = bound - 0.5*sum(log(Dff));
bound = bound - sum(log(diag(LD)));

%delta 1: trace-like term
bound = bound - 0.5 * (1 - alpha) / alpha*sum(log(Dff./sn));

%delta 2
bound = bound - 1.0/alpha*sum(log(diag(LQ)));
bound = bound + sum(log(diag(La)));
bound = bound - sum(log(diag(LSa)));
bound = -bound;