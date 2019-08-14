clear all, clc,

%% Load dataset:
dataID = 'TFlexADRC_RN20.mat';
%dataID = 'sarcos_inv.mat'
[xTrain, yTrain, Ts] = selectData(dataID,'fig',false);
[dof, N] = size(xTrain');

yTrain  = yTrain(:,1)';
xTrain  = xTrain';

%Normalize data
%
mu_X   = mean(xTrain');
sig_X  = std(xTrain');
xTrain = ((xTrain' - mu_X) ./ sig_X)';
xTrain = [[0:N-1]*Ts;xTrain];

mu_Y   = mean(yTrain');
sig_Y  = std(yTrain');
yTrain = ((yTrain' - mu_Y) ./ sig_Y)';
%}

%% (Hyper)parameters 
%Hyperparameters 
sn  = 1;          % Noise variance
sf   = 0.5;           % Signal variance
l    = [1 ones(1,dof)];   % characteristic lengthscale

%Combine into 1 vector
hyp  = [sf,l];

fprintf('  ----  Incremental FITC - Bijl2015  ----  \n')
%% Data selection
i_f = [1:100];
i_u = [1:2:100];
i_s = [1:110];
i_loop  = [100:200];
i_plot  = [200:250];
i_total = [1:100,101:200];
i_sFinal= [100:205];
uRatio  = 1;     % update ratio of inducing points

f  = xTrain(:,i_f)';
u  = xTrain(:,i_u)';
s  = xTrain(:,i_s)';
loop   = xTrain(:,i_loop)';
sFinal = xTrain(:,i_sFinal)';

yf = yTrain(:,i_f)';
ys = yTrain(:,i_s)';
yloop   = yTrain(:,i_loop)';
ysFinal = yTrain(:,i_sFinal)';

%% Hyperparameter optimization
options = optimset;
options.Display = 'iter-detailed';
options.MaxIter = 500;
%[nlml] = nlml_I_FITC(hyp, sn, u, f, yf, 'VFE')
[hyp_sn nlml] = fminsearch(@(hyp) nlml_I_FITC(hyp, u, f, yf, 'FITC'),[hyp,sn],options);
hyp = abs(hyp_sn(1:end-1));
sn  = abs(hyp_sn(end));
sn2 = sn^2;

%% Run FITC over initial window
tic
jitter = 1e-6;
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

mu_1 = mu_s;
var_1 = var_s;
mu_u1 = mu_u;

toc

%% Update inducing points 
u_old = u; % Store for plotting

% Decide which point to remove
nRemove = floor(uRatio*Mu);
if uRatio == 1
    i_del   = 1:nRemove-1;
else
    i_del   = unique(randi(Mu,1,nRemove));
end
nRemove = size(i_del,2);

u(i_del,:)  = [];       % Remove from inducing points
mu_u(i_del) = [];       % Remove from mean
var_u (:,i_del) = [];   % Remove from var
var_u (i_del,:) = [];   % "             "
Kuu (:,i_del) = [];     % Remove from Covariance Matrix
Kuu (i_del,:) = [];     % "             "

%Select new inducing points
i_new = floor(linspace(1,size(sFinal,1),nRemove));
%i_new = sort(randi(size(loop,1),1,nRemove));
u_new = sFinal(i_new,:);
Kuup  = SEcov(u,u_new,hyp);
Kupup = SEcov(u_new,u_new,hyp) + eye(nRemove)*sn2;

%Update mu_u    (equation 3 - bijl2016)
Lu         = chol(Kuu,'lower');
Luinv_Kuup = solve_lowerTriangular(Lu,Kuup);
Luinv_mu_u = solve_lowerTriangular(Lu,mu_u);
mu_u       = [mu_u                  ; 
              Luinv_Kuup'*Luinv_mu_u];

%Update var_u   (equation 3 - bijl2016)
Luinv_var_u = solve_lowerTriangular(Lu,var_u);
Luinv_Kuup  = solve_lowerTriangular(Lu,Kuup);
var_uup     = Luinv_var_u'*Luinv_Kuup;
D           = Kuu - var_u;
Luinv_D     = solve_lowerTriangular(Lu,D);
Kuuinv_Kuup = solve_linSystem(Kuu,Kuup);
var_upup    = Kupup - Luinv_Kuup'*Luinv_D*Kuuinv_Kuup;
var_u       = [var_u   , var_uup ;
               var_uup', var_upup];
           
% New vector of ind. point + recalculate some stuff
u   = [u;u_new];
Kuu = SEcov(u,u,hyp) + eye(Mu)*sn2;
Lu  = chol(Kuu,'lower');
u_new = u;  % Store for the SSGP algorithm


%% Update (p indicates plus 1 timestep)
i_s_copy = i_s;

tic
iter = 0;
for jj = i_loop
    i_s = jj+1;
    s   = xTrain(:,i_s)';
    
    fp  = xTrain(:,jj)';
    yfp = yTrain(:,jj)';
        
    Kfpfp = SEcov(fp,fp,hyp);
    Kufp  = SEcov(u,fp,hyp);
    Kss   = SEcov(s,s,hyp);
    Kus   = SEcov(u,s,hyp);

    %Equation 8
    Luinv_Kufp = solve_lowerTriangular(Lu,Kufp);
    Qfpfp = Luinv_Kufp'*Luinv_Kufp;
    Lambda_fpfp = diag(Kfpfp - Qfpfp);
    
    %Equation 44b
    LuTinv_Kufp_Luinv = solve_lowerTriangular(Lu',Luinv_Kufp);
    Pnp = (Lambda_fpfp.^-1).*inv(Lu)'*Luinv_Kufp*Luinv_Kufp'*inv(Lu);
    
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
    Kus   = SEcov(u,s,hyp);
    D = Kuu - var_u;
    Luinv_D = solve_lowerTriangular(Lu,D);
    Kuuinv_Kus = solve_linSystem(Kuu,Kus);
    var_sp = Kss - Luinv_Kus'*Luinv_D*Kuuinv_Kus;
    
    mu_u = mu_up;
    var_u = var_up;
    
    mu_s  = mu_sp;
    var_s = var_sp;
    iter = iter + 1;
end
timer = toc;
t_run = toc/iter;
fprintf('Number of inducing points:     %i\n',Mu);
fprintf('Elapsed time:           total: %.5f ms \n',timer/1e-3);
fprintf('                per iteration: %f ms \n',t_run/1e-3);

%% Final iteration
i_s = i_s_copy;
s = xTrain(:,i_s);

i_s = i_sFinal;
s2  = xTrain(:,i_s)';

fp  = xTrain(:,jj)';
yfp = yTrain(:,jj)';

Kuu   = SEcov(u,u,hyp) + eye(Mu)*sn2;
Kus   = SEcov(u,s2,hyp);
Kss = SEcov(s2,s2,hyp);
Kfpfp = SEcov(fp,fp,hyp);
Kufp  = SEcov(u,fp,hyp);

%Equation 8
Lu  = chol(Kuu,'lower');
Luinv_Kufp = solve_lowerTriangular(Lu,Kufp);
Qfpfp = Luinv_Kufp'*Luinv_Kufp;

Lambda_fpfp = diag(Kfpfp - Qfpfp);

%Equation 44b
LuTinv_Kufp_Luinv = solve_lowerTriangular(Lu',Luinv_Kufp);
Pnp = (Lambda_fpfp.^-1).*inv(Lu)'*Luinv_Kufp*Luinv_Kufp'*inv(Lu);

%Equation 45
%var_up = (eye(Mu) - var_u*Pnp./(1+trace(var_u*Pnp)))*var_u;
var_up = var_u - (var_u*Pnp*var_u)/(1+trace(var_u*Pnp));

%Equation 47
Luinv_var_upT = solve_lowerTriangular(Lu,var_up');
mu_up = (eye(Mu) - var_u*Pnp/(1+trace(var_u*Pnp)))*mu_u + (Lambda_fpfp^-1)*Luinv_var_upT'*Luinv_Kufp*yfp;

%Prediction
%Equation 28
Luinv_Kus = solve_lowerTriangular(Lu,Kus);
Luinv_mu_up = solve_lowerTriangular(Lu,mu_up);
mu_s = Luinv_Kus'*Luinv_mu_up;

%Equation 29
D = Kuu - var_u;
Luinv_D = solve_lowerTriangular(Lu,D);
Kuuinv_Kus = solve_linSystem(Kuu,Kus);
var_s = Kss - Luinv_Kus'*Luinv_D*Kuuinv_Kus;

mu_u = mu_up;
var_u = var_up;

%% scale back up
%{
% X
xTrain = xTrain.*sig_X' + mu_X';
f      = f.*sig_X + mu_X;
s      = s.*sig_X' + mu_X';
s2     = s2.*sig_X + mu_X;
loop   = loop.*sig_X + mu_X;
u_old  = u_old.*sig_X + mu_X;
u      = u.*sig_X + mu_X;

%Y
yTrue  = yTrue.*sig_Y + mu_Y;
yTrain = yTrain.*sig_Y + mu_Y;
mu_1   = mu_1.*sig_Y + mu_Y;
mu_s   = mu_s.*sig_Y + mu_Y;
yf     = yf.*sig_Y + mu_Y;
var_1  = var_1.*sig_Y + mu_Y;
var_s  = var_s.*sig_Y + mu_Y;
yloop  = yloop.*sig_Y + mu_Y;
%}

%% Results
fSize = 12;
resultsIFITC = figure(1);clf(resultsIFITC);
sphandle(1,1) = subplot(2,1,1);
hold on
ha(1) = scatter(f(:,1),yf(:,1),'xb');
%ha(2).MarkerFaceAlpha = .6;
%ha(2).MarkerEdgeAlpha = .6;
%ha(1) = plot(xTrain(1,i_plot),yTrue(1,i_plot),'-k','LineWidth',1.5);
ha(3) = plot(s(1,:),mu_1,'r','LineWidth',1.5);
ha(4) = plot(s(1,:),mu_1 + 2*sqrt(diag(var_1+ sn^2)),'k');
plot(s(1,:),mu_1 - 2*sqrt(diag(var_1+ sn^2)),'k');
ha(2) = scatter(u_old(:,1),zeros(size(u,1),1),ones(size(u,1),1)*10,'ok','filled');
legend(ha,'Initial data','Inducing points','Predicted mean',...
    'Predictive var.','Interpreter','Latex','FontSize',fSize);
title('Incremental FITC - Bijl2015','Interpreter','Latex','FontSize',fSize+8)
ylabel('y','Interpreter','Latex','FontSize',fSize+4)
hold off
clear ha

sphandle(2,1) = subplot(2,1,2);
hold on
ha(1) = scatter(f(:,1),yf,'xk');
ha(1).MarkerFaceAlpha = .6;
ha(1).MarkerEdgeAlpha = .6;
ha(2) = scatter(loop(:,1),yloop,'xb');
ha(6) = scatter(xTrain(1,i_plot),yTrain(1,i_plot),'xr');
ha(4) = plot(s2(:,1),mu_s,'-r','LineWidth',1.5);
ha(5) = plot(s2(:,1),mu_s + 2*sqrt(diag(var_s+ sn^2)),'k');
plot(s2(:,1),mu_s - 2*sqrt(diag(var_s + sn^2)),'k');
ha(3) = scatter(u(:,1),zeros(size(u,1),1),ones(size(u,1),1)*10,'ok','filled');
ylabel('y','Interpreter','Latex','FontSize',fSize+4)
xlabel('t (s)','Interpreter','Latex','FontSize',fSize+4)
legend(ha,'Initial data','Incremental data',...
    'Inducing points','Predicted mean','Predictive var.','Future points',...
'Interpreter','Latex','FontSize',fSize);
hold off
clear ha han
[resultsIFITC,sphandle] = subplots(resultsIFITC,sphandle);

%% Error

error = rms(mu_s - yTrain(1,i_s)');
fprintf('RMS error:  final interval: %f \n',error)

%}