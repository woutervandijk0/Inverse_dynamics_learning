function [La, Lb, LD, LSa, LDinv_c, Dff, Sainv_ma, LM, Q, LQ] = osgpBuildTerms(hyp,sn,f,yf,a,b,Saa,ma,Kaa_old,alpha)
jitter = 1e-4;
Ma = length(a);
Mb = length(b);

Kfdiag  = diag(SEcov(f,f,hyp));
Kbf     = SEcov(b,f,hyp);
Kbb     = SEcov(b,b,hyp) + eye(Mb)*jitter;
Kba     = SEcov(b,a,hyp);
Kaa_cur = SEcov(a,a,hyp) + eye(Ma)*jitter;
Kaa     = Kaa_old + eye(Ma)*jitter;

Lb          = chol(Kbb,'lower');
Lbinv_Kbf   = solve_lowerTriangular(Lb,Kbf);

Qfdiag      = Kfdiag - diag(Lbinv_Kbf'*Lbinv_Kbf);
%Qfdiag      = Kfdiag' - sum(Lbinv_Kbf.^2);
Dff         = sn.^2 + alpha.*Qfdiag;
Lbinv_Kbf_LDff = Lbinv_Kbf./sqrt(Dff');
d1 = Lbinv_Kbf_LDff*Lbinv_Kbf_LDff';

Lbinv_Kba = solve_lowerTriangular(Lb, Kba); 
Kab_Lbinv = Lbinv_Kba';

%Sainv_Kab_Lbinv = Saa\Kab_Lbinv;
Sainv_Kab_Lbinv = solve_linSystem(Saa,Kab_Lbinv);

%Kainv_Kab_Lbinv = Kaa\Kab_Lbinv;
Kainv_Kab_Lbinv = solve_linSystem(Kaa,Kab_Lbinv);

Da_Kab_Lbinv = Sainv_Kab_Lbinv - Kainv_Kab_Lbinv;
d2 = Lbinv_Kba*Da_Kab_Lbinv;

Kaadiff = Kaa_cur - Kab_Lbinv*Lbinv_Kba;
LM = chol(Kaadiff,'lower');
LMT = LM';
%Sainv_LM = Saa\LM;
%Kainv_LM = Kaa\LM;
Sainv_LM = solve_linSystem(Saa,LM);
Kainv_LM = solve_linSystem(Kaa,LM);

SK_LM = Sainv_LM - Kainv_LM;
LMT_SK_LM = LMT*SK_LM;
Q = eye(Ma) + alpha*LMT_SK_LM;
LQ = chol(Q,'lower');

LMT_Da_Kab_Lbinv = LMT*Da_Kab_Lbinv;
%Qinv_t1 = Q\LMT_Da_Kab_Lbinv;
Qinv_t1 = solve_linSystem(Q,LMT_Da_Kab_Lbinv);
t1_Qinv_t1 = LMT_Da_Kab_Lbinv'*Qinv_t1;
d3 = -alpha * t1_Qinv_t1;

D = eye(Mb) + d1 + d2 + d3;
D = D + eye(Mb)* jitter;
LD = chol(D,'lower');

%Sainv_ma           = Saa\ ma;
Sainv_ma            = solve_linSystem(Saa,ma);
LMT_Sainv_ma        = LMT*Sainv_ma;
Lbinv_Kba_Da        = Da_Kab_Lbinv';
Lbinv_Kba_Da_LM     = Lbinv_Kba_Da*LM;
%Qinv_LMT_Sainv_ma   = Q\LMT_Sainv_ma;
Qinv_LMT_Sainv_ma   = solve_linSystem(Q,LMT_Sainv_ma);

Sinv_y              = (yf./Dff')';
c1      = Lbinv_Kbf*Sinv_y;
c2      = Lbinv_Kba*Sainv_ma;
c3      = - alpha*Lbinv_Kba_Da_LM*Qinv_LMT_Sainv_ma;
c       = c1 + c2 + c3;

LDinv_c = solve_lowerTriangular(LD, c);
LSa     = chol(Saa,'lower');
La      = chol(Kaa,'lower');