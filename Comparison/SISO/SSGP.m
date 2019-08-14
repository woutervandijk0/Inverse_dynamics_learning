
fig2pdf = 0;
pdf2ipe = 0;

alpha  = 0.5;   % VFE,  alpha = 0
                % SPEP, 0 < alpha < 1
                % FITC, alpha = 1

fprintf('  ----  Streaming sparse GP - Bui2015  ----  \n')
%% (Offline) Streaming Sparse Gaussian Process (initial step)
i_f = 1:500;
i_s = [1:10:500];
i_b = [1:10:500];

%a  = xTrain(i_a)';      % Old inducing points
b  = xTrain(:,i_b)';     % New inducing points
f  = xTrain(:,i_f)';     % Training points
s  = xTrain(:,i_s)';     % Test points

%ya = yTrain(i_b)';
yb = yTrain(i_b)';    
yf = yTrain(i_f)';
ys = yTrain(i_s)';
err = yf;

tic
%Ma = length(a);
Mb = length(b);
Mf = length(f);
Ms = length(s);

Kff     = SEcov(f,f,hyp);
Kfdiag  = diag(Kff);
Kbf     = SEcov(b,f,hyp);
Kbb     = SEcov(b,b,hyp) + eye(Mb)*jitter;
Kbs     = SEcov(b,s,hyp);

Lb          = chol(Kbb,'lower');
Lbinv_Kbf   = solve_lowerTriangular(Lb,Kbf);

Lbinv_Kbs   = solve_lowerTriangular(Lb, Kbs);

Qfdiag      = Kfdiag - diag(Lbinv_Kbf'*Lbinv_Kbf);
%Qfdiag      = Kfdiag' - sum(Lbinv_Kbf.^2);
Dff         = sn + alpha.*Qfdiag;
Lbinv_Kbf_LDff = Lbinv_Kbf./sqrt(Dff');

D = eye(Mb) + Lbinv_Kbf_LDff*Lbinv_Kbf_LDff';
LD = chol(D,'lower');

LDinv_Lbinv_Kbs = solve_lowerTriangular(LD, Lbinv_Kbs);
LDinv_Lbinv_Kbf = solve_lowerTriangular(LD,Lbinv_Kbf);

Sinv_y          = (yf./Dff')';
c               = Lbinv_Kbf*Sinv_y;
LDinv_Lbinv_Kbf_c  = LDinv_Lbinv_Kbf*Sinv_y;
LDinv_c         = solve_lowerTriangular(LD,c);


%% Approximate log marginal Likelihood
%{
bound = 0;
% constant term
bound = - 0.5*Mf*log(2*pi);
% quadratic term
bound = bound - 0.5 * sum(err.^2/ Dff');
bound = bound + 0.5 * sum(LDinv_c.^2);

% log det term
bound = bound - 0.5 * sum(log(Dff));
bound = bound - sum(log(diag(LD)));

% trace-like term
bound = bound - 0.5*(1-alpha)/alpha * sum(log(Dff./sn));
%}
%% Prediction 
%Predictive mean
%m = LDinv_Lbinv_Kbs'*LDinv_Lbinv_Kbf_c;
m = LDinv_Lbinv_Kbs'*LDinv_c;

%Prediction variance (matrix)
Kss  = SEcov(s,s,hyp) + eye(Ms)*jitter;
var1 = Kss;
var2 = -Lbinv_Kbs'*Lbinv_Kbs;
var3 = LDinv_Lbinv_Kbs'*LDinv_Lbinv_Kbs;
Su   = var1 + var2 + var3;

%Prediction variance (vector)
var  = diag(Su);
toc
%% Plot result 
resultsSSGP = figure(2); clf(2);
sphandle(1,1) = subplot(2,1,1);
hold on
ha(2) = scatter(f(:,1),yf,'xb');
ha(2).MarkerFaceAlpha = .6;
ha(2).MarkerEdgeAlpha = .6;
ha(3) = scatter(b(:,1),zeros(size(b,1),1),ones(size(b,1),1)*10,'ok','filled');
ha(1) = plot(xTrain(1,i_plot),yTrue(i_plot,1),'k','LineWidth',1.5);
ha(4) = plot(s(:,1),m,'-r','LineWidth',2);
ha(5) = plot(s(:,1),m + 2*sqrt(var+sn2),'-k');
        plot(s(:,1),m - 2*sqrt(var+sn2),'-k');
ylabel('y','Interpreter','Latex','FontSize',fSize+4);
title('Streaming Sparse GP - Bui2017','Interpreter','Latex','FontSize',fSize+8);
legend(ha,'True function','Data in window','Inducing points','Predicted mean',...
    'Predictive var.','Interpreter','Latex','FontSize',fSize);
hold off


sphandle(2,1) = subplot(2,1,2);
hold on
han(3) = scatter(f(:,1),yf,'xk');
han(3).MarkerFaceAlpha = .5; 
han(3).MarkerEdgeAlpha = .5;
hold off

%% Online Streaming Sparse Gaussian Process
i_f = 600:700;
i_s = [1:700];
f   = xTrain(:,i_f)';     % Training points
s   = xTrain(:,i_s)';     % Test points
a   = b;
yf  = yTrain(i_f)';
ys  = yTrain(i_s)';

tic;
M       = length(a);
M_old   = floor(0.7*M);
M_new   = M - M_old;
old_Z   = b(randi(M,1,M_old),:);
new_Z   = f(randi(size(f,1),1,M_new),:);
b       = [old_Z;new_Z];
b       = u_new; % From I_FITC

Ma = length(a);
Mb = length(b);
Mf = length(f);
Ms = length(s);

Saa = Su;
ma  = m;
Kaa_old = Kbb;
Kfdiag  = diag(SEcov(f,f,hyp));
Kbf     = SEcov(b,f,hyp);
Kbb     = SEcov(b,b,hyp) + eye(Ma)*jitter;
Kba     = SEcov(b,a,hyp);
Kaa_cur = SEcov(a,a,hyp) + eye(Ma)*jitter;
Kaa     = Kaa_old + eye(Ma)*jitter;

Lb          = chol(Kbb,'lower');
Lbinv_Kbf   = solve_lowerTriangular(Lb,Kbf);

Qfdiag      = Kfdiag - diag(Lbinv_Kbf'*Lbinv_Kbf);
%Qfdiag      = Kfdiag' - sum(Lbinv_Kbf.^2);
Dff         = sn + alpha.*Qfdiag;
Lbinv_Kbf_LDff = Lbinv_Kbf./sqrt(Dff');
d1 = Lbinv_Kbf_LDff*Lbinv_Kbf_LDff';

Lbinv_Kba = solve_lowerTriangular(Lb, Kba); 
Kab_Lbinv = Lbinv_Kba';

Sainv_Kab_Lbinv = Saa\Kab_Lbinv;
Kainv_Kab_Lbinv = Kaa\Kab_Lbinv;
Da_Kab_Lbinv = Sainv_Kab_Lbinv - Kainv_Kab_Lbinv;
d2 = Lbinv_Kba*Da_Kab_Lbinv;

Kaadiff = Kaa_cur - Kab_Lbinv*Lbinv_Kba;
LM = chol(Kaadiff,'lower');
LMT = LM';
Sainv_LM = Saa\LM;
Kainv_LM = Kaa\LM;
SK_LM = Sainv_LM - Kainv_LM;
LMT_SK_LM = LMT*SK_LM;
Q = eye(Ma) + alpha*LMT_SK_LM;
LQ = chol(Q,'lower');

LMT_Da_Kab_Lbinv = LMT*Da_Kab_Lbinv;
Qinv_t1 = Q\LMT_Da_Kab_Lbinv;
t1_Qinv_t1 = LMT_Da_Kab_Lbinv'*Qinv_t1;
d3 = -alpha * t1_Qinv_t1;

D = eye(Mb) + d1 + d2 + d3;
D = D + eye(Mb)* jitter;
LD = chol(D,'lower');

Sainv_ma            = Saa\ma;
LMT_Sainv_ma        = LMT*Sainv_ma;
Lbinv_Kba_Da        = Da_Kab_Lbinv';
Lbinv_Kba_Da_LM     = Lbinv_Kba_Da*LM;
Qinv_LMT_Sainv_ma   = Q\LMT_Sainv_ma;
Sinv_y              = (yf./Dff')';
c1      = Lbinv_Kbf*Sinv_y;
c2      = Lbinv_Kba*Sainv_ma;
c3      = - alpha*Lbinv_Kba_Da_LM*Qinv_LMT_Sainv_ma;
c       = c1 + c2 + c3;

LDinv_c = solve_lowerTriangular(LD, c);
LSa     = chol(Saa,'lower');
La      = chol(Kaa,'lower');

%Predict
Kbs = SEcov(b,s,hyp);
Lbinv_Kbs = solve_lowerTriangular(Lb, Kbs);
LDinv_Lbinv_Kbs = solve_lowerTriangular(LD, Lbinv_Kbs);

%Predictive mean
m = LDinv_Lbinv_Kbs'*LDinv_c;

%Prediction variance (matrix)
Kss = SEcov(s,s,hyp) + eye(Ms)*jitter;
var1 = Kss;
var2 = -Lbinv_Kbs'*Lbinv_Kbs;
var3 = LDinv_Lbinv_Kbs'*LDinv_Lbinv_Kbs;
Su  = var1 + var2 + var3;

%Prediction variance (vector)
var = diag(Su);


timer = toc;
fprintf('Number of inducing points:     %i\n',Mu);
fprintf('Elapsed time:           total: %.5f ms\n',timer/1e-3)

%% Plot results
resultsSSGP;
sphandle(2,1);
hold on
han(2) = plot(f(:,1),yf,'xb');
han(4) = scatter(b(:,1),zeros(size(b,1),1),ones(size(b,1),1)*10,'ok','filled');
han(1) = plot(xTrain(1,i_plot),yTrue(i_plot,1),'k','LineWidth',1.5);
han(5) = plot(s(:,1),m,'-r','LineWidth',2);
han(6) = plot(s(:,1),m + 2*sqrt(var + sn2),'-k');
         plot(s(:,1),m - 2*sqrt(var + sn2),'-k');
legend(han,'True function','Data in window','Data outside window',...
    'Inducing points','Predicted mean','Predictive var.','Interpreter','Latex','FontSize',fSize);
%xlim([0,4]);
xlabel('t (s)','Interpreter','Latex','FontSize',fSize+4);
ylabel('y','Interpreter','Latex','FontSize',fSize+4);
hold off

[resultsSSGP,sphandle] = subplots(resultsSSGP,sphandle);

%% Error
error = rms(m - yTrain(i_s,1));
fprintf('RMS error:  complete interval: %f \n',error)

error = rms(m(i_total) - yTrain(i_total,1));
fprintf('            measured interval: %f \n\n',error)

%% Save Figures
if(fig2pdf)
    saveas(resultsIFITC,fullfile(pwd,'Images','IFITC.pdf'));
    saveas(resultsISSGP,fullfile(pwd,'Images','ISSGP.pdf'));
    saveas(resultsSSGP,fullfile(pwd,'Images','SSGP.pdf'));
end

%% PDF2IPE
if(pdf2ipe)
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''});
end

%%
xTrain  = xTrain;
yTrain  = yTrain';
yTrue   = yTrue';