clear all, clc

%fromData

%% (Hyper)parameters 
%Hyperparameters 
l   = 0.1;        % characteristic lengthscale
sf  = 1;         % Signal variance
sn  = 0.1;       % Noise variance
sn2 = sn^2;
hyp = [sf,l];

%% Load dataset:
%{
dataID = 'TFlexADRC_RN20.mat';
%dataID = 'TFlex1D5G.mat';
%dataID = 'TFlex1D-2.mat';
%[xTrain, yTrain, Ts] = selectData(dataID,'fig',false);
yTrue   = yTrain;
xTrain  = xTrain';

%
sf   = 1.7723e+03;
l    = [0.2989    0.0022    0.00001];
% 
sf   = 0.0589
l    = [114.9646  310.7584  220.8015];
% 
sf = 0.9301
l  = [13.8997   22.6550    4.1100];


hyp  = [sf,l];
%}

% Create training data (random draw from GP):
%
xTrain = linspace(0,20,5000);           % Input
KK      = SEcov(xTrain',xTrain',hyp);   % SE covariance kernel
randX   = rand(5000,1)-1/2;             % Random vector
yTrue   = KK*randX;                     % Underlying function
yTrain  = yTrue + randn(5000,1)*sn;     % Add noise
%}

yTrain  = yTrain';
yTrue   = yTrue';
[dof, N] = size(xTrain);

%Normalize data
%{
mu_X   = mean(xTrain');
sig_X  = std(xTrain');
xTrain = ((xTrain' - mu_X) ./ sig_X)';

mu_Y   = mean(yTrain');
sig_Y  = std(yTrain');
yTrain = ((yTrain' - mu_Y) ./ sig_Y)';
yTrue  = ((yTrue' - mu_Y) ./ sig_Y)';
sn     = 0.1/sig_Y;       % Noise variance
sn2    = sn^2;

%}

fprintf('  ----  Incremental FITC - Bijl2015  ----  \n')
%% Data selection
i_f = [400:500];
i_u = [400:10:510];
i_s = [400:510];
i_loop  = [600:700];
i_plot  = [400:550];
i_total = [1:500,600:700];

f  = xTrain(:,i_f)';
u  = xTrain(:,i_u)';
s  = xTrain(:,i_s)';
loop = xTrain(:,i_loop)';

yf = yTrain(:,i_f)';
ys = yTrain(:,i_s)';
yloop = yTrain(:,i_loop)';

%% Run FITC over initial window
tic
jitter = 1e-6;
Mu  = length(u);
Mf  = length(f);
Kuu = SEcov(u,u,hyp) + eye(Mu)*jitter;
Kuf = SEcov(u,f,hyp);
Kfu = SEcov(f,u,hyp);
Kus = SEcov(u,s,hyp);
Kss = SEcov(s,s,hyp);
Kff = SEcov(f,f,hyp) + eye(Mf)*jitter;

%Equation 8
Lu  = chol(Kuu,'lower');
Luinv_Kuf = solve_lowerTriangular(Lu,Kuf);
Qff = Luinv_Kuf'*Luinv_Kuf;

%equation 20 & 21
Lambda_ff = diag(Kff - Qff);
Kff_hat   = Qff + diag(Lambda_ff);

%Equation 27 (zero mean)
B  = Kuu + Kuf*diag(1./Lambda_ff)*Kuf';
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
nRemove = floor(0.5*Mu);
i_del   = unique(randi(Mu,1,nRemove));
nRemove = size(i_del,2);

u(i_del,:)    = [];       % Remove from inducing points
mu_u(i_del)   = [];       % Remove from mean
var_u (:,i_del) = [];   % Remove from var
var_u (i_del,:) = [];   % "             "
Kuu (:,i_del) = [];     % Remove from Covariance Matrix
Kuu (i_del,:) = [];     % "             "

%Select new inducing points
i_new = floor(linspace(1,size(loop,1),nRemove));
%i_new = sort(randi(size(loop,1),1,nRemove));
u_new = loop(i_new,:);
Kuup  = SEcov(u,u_new,hyp);
Kupup = SEcov(u_new,u_new,hyp) + eye(nRemove)*jitter;

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
Kuu = SEcov(u,u,hyp) + eye(Mu)*jitter;
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

i_s = [1:700];
s2  = xTrain(:,i_s)';

fp  = xTrain(:,jj)';
yfp = yTrain(:,jj)';

Kuu   = SEcov(u,u,hyp) + eye(Mu)*jitter;
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
ha(2) = scatter(f(:,1),yf(:,1),'xb');
%ha(2).MarkerFaceAlpha = .6;
%ha(2).MarkerEdgeAlpha = .6;
ha(1) = plot(xTrain(1,i_plot),yTrue(1,i_plot),'-k','LineWidth',1.5);
ha(4) = plot(s(1,:),mu_1,'r','LineWidth',1.5);
ha(5) = plot(s(1,:),mu_1 + 2*sqrt(diag(var_1+sn2)),'k');
plot(s(1,:),mu_1 - 2*sqrt(diag(var_1+sn2)),'k');
ha(3) = scatter(u_old(:,1),zeros(size(u,1),1),ones(size(u,1),1)*10,'ok','filled');
legend(ha,'True function','Initial data','Inducing points','Predicted mean',...
    'Predictive var.','Interpreter','Latex','FontSize',fSize);
title('Incremental FITC - Bijl2015','Interpreter','Latex','FontSize',fSize+8)
ylabel('y','Interpreter','Latex','FontSize',fSize+4)
hold off
clear ha
%{
sphandle(2,1) = subplot(2,1,2);
hold on
ha(2) = scatter(f(:,1),yf,'xk');
ha(2).MarkerFaceAlpha = .6;
ha(2).MarkerEdgeAlpha = .6;
ha(3) = scatter(loop(:,1),yloop,'xb');
ha(1) = plot(xTrain(1,i_plot),yTrue(1,i_plot),'-k','LineWidth',1.5);
ha(5) = plot(s2(:,1),mu_s,'-r','LineWidth',1.5);
ha(6) = plot(s2(:,1),mu_s + 2*sqrt(diag(var_s+sn2)),'k');
plot(s2(:,1),mu_s - 2*sqrt(diag(var_s+sn2)),'k');
ha(4) = scatter(u(:,1),zeros(size(u,1),1),ones(size(u,1),1)*10,'ok','filled');
ylabel('y','Interpreter','Latex','FontSize',fSize+4)
xlabel('t (s)','Interpreter','Latex','FontSize',fSize+4)
legend(ha,'True function','Initial data','Incremental data',...
    'Inducing points','Predicted mean','Predictive var.',...
'Interpreter','Latex','FontSize',fSize);
hold off
clear ha han
%}
[resultsIFITC,sphandle] = subplots(resultsIFITC,sphandle);

%% Error
error = rms(mu_s - yTrain(1,i_s)');
fprintf('RMS error:  complete interval: %f \n',error)

error = rms(mu_s(i_total) - yTrain(1,i_total)');
fprintf('            measured interval: %f \n\n',error)

%% Run other methods
%Run incremental Sparse Spectrum GP script
%I_SSGP
%Run Streaming Sparse GP script
%SSGP