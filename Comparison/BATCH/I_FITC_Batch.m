clear all, clc,
fprintf('  ----  Incremental FITC - Bijl2015  ----  \n')

%% Load dataset:
Ts = 1/1000;
dataID = 'TFlexADRC_RN20.mat';
dataID = 'TFlexADRC_RN20_Isp.mat';
%dataID = 'sarcos_inv.mat';
%dataID = 'TFlex1D5G.mat';
%dataID = 'TFlex1D-2.mat'
%dataID = 'sarcos_inv.mat';
%dataID = 'BaxterRhythmic.mat';
%dataID = 'BaxterRand.mat';
[xTrain, yTrain, Ts] = selectData(dataID,'fig',false);
%{
load('ISSGP.mat');
iStart = 100/Ts;
xTrain = xTrain(:,iStart:end)';
yTrain = FB(iStart:end,1);
%}

if strcmp( dataID,'TFlexADRC_RN20_Isp.mat')
    xTrain(1:3,:) = [];
    yTrain(end-3:3,:) = [];
end

[dof, N] = size(xTrain');
yTrain  = yTrain(:,1)';
xTrain  = xTrain';
xSp = xTrain;
%xSp(3,:)  = movmean(xTrain(3,:),5);

T       = [[0:N-1]*Ts];       % Time 

%Normalize data
% X
mu_X   = mean(xTrain');
sig_X  = std(xTrain');
xTrain = ((xTrain' - mu_X) ./ sig_X)';
xSp    = ((xSp' - mu_X) ./ sig_X)';
%xSp(:,1:3) = [];

% Y
mu_Y   = mean(yTrain');
sig_Y  = std(yTrain');
yTrain = ((yTrain' - mu_Y) ./ sig_Y)';

%% (Hyper)parameters 
%Hyperparameters 
sn  = 6;          % Noise variance
sf   = 500;           % Signal variance
l    = [ones(1,dof)];   % characteristic lengthscale
%Combine into 1 vector
hyp  = [sf,l];

%overwrite hyperparam
%sn  = 0.2327;
%hyp = [2.4834    0.1895    0.5970    1.2142];

%% Data selection (intial)
i_f = [1:250];
i_u = [1:5:i_f(end)];
i_s = i_f;
i_loop  = [i_f(end)+1:1001];
i_loop  = 1001:50000;

f  = xTrain(:,i_f)';
u  = xTrain(:,i_u)';
s  = xTrain(:,i_s)';
loop   = xTrain(:,i_loop)';

yf = yTrain(:,i_f)';
ys = yTrain(:,i_s)';
yloop   = yTrain(:,i_loop)';

Mf  = length(i_f);
%% Hyperparameter optimization
fprintf('Updating hyperparameters...')
options = optimset;
options.Display = 'final';
options.MaxIter = 500;
%[nlml] = nlml_I_FITC(hyp, sn, u, f, yf, 'VFE')
[hyp_sn nlml] = fminsearch(@(hyp) nlml_I_FITC(hyp, u, f, yf, 'VFE'),[hyp,sn],options);
hyp = abs(hyp_sn(1:end-1));
sn  = abs(hyp_sn(end));
sn2 = sn^2;
sn_old = sn;
%}

options.MaxIter = 20;
fprintf('  ----  Incremental FITC - Bijl2015  ----  \n')
%% Run FITC over initial window
[mu_s, var_s, mu_u, var_u, Kuu] = FITC(hyp,sn,u,f,yf,s);

%% Update (p indicates plus 1 timestep)
i_s_copy = i_s;
u_old    = u;
pred = zeros(1,length(i_loop));
vari = zeros(1,length(i_loop));
yTest = zeros(1,length(i_loop));
iTest = zeros(1,length(i_loop));

%Keep Nkeep inducing points
Nkeep = 20;
Nremove = size(u,1)-Nkeep;
[u,Kuu,Lu,mu_u,var_u,Mu] = updateInducing(hyp,sn,u,mu_u,var_u,Kuu,u(Nremove,:),Nremove);


fprintf('Expected simulation time: %.3f seconds ...\n',length(i_loop)*1e-3)
tic
iter = 1;
for jj = i_loop
    % New data
    i_sNew = jj+1;
    
    sNew   = xTrain(:,i_sNew)';     % New test point
    uNew   = xTrain(:,jj)';         % New inducing point
    yTrue  = yTrain(:,i_sNew)';     % Such that we can compare later
    sNew   = xSp(:,i_sNew)';
    %uNew   = xSp(:,jj)'; % New inducing point
    
    %{
    beta = 0.5;
    if (mod(jj,floor(i_loop(end)/19))==0) && (iter>2)
        
        i_fNew = [(jj-(Mf)):jj];
        fNew  = xTrain(:,i_fNew)';
        yfNew = yTrain(:,i_fNew)';
        
        [hyp_sn nlml] = fminsearch(@(hyp) nlml_I_FITC(hyp, u, fNew, yfNew, 'VFE'),[hyp,sn],options);
        hyp = (1-beta)*hyp + beta*abs(hyp_sn(1:end-1));
        sn  = (1-beta)*sn  + beta*abs(hyp_sn(end));
        sn2 = sn^2;
    end
    %}
    
    fp  = xTrain(:,jj)';    % New training point
    yfp = yTrain(:,jj)';    % New training point
    
    % Update inducing points
    if mod(jj,10) == 0
        [u,Kuu,Lu,mu_u,var_u,Mu] = updateInducing(hyp,sn,u,mu_u,var_u,Kuu,xTrain(:,jj-100:jj)',1);
    end
    %if mod(jj,1) == 0
        [u,Kuu,Lu,mu_u,var_u,Mu] = updateInducing(hyp,sn,u,mu_u,var_u,Kuu,uNew,0);
    %end
       
    % Make prediction
    [mu, var ,mu_u,var_u] = IncrementalFITC(hyp,sn,u,sNew,fp,yfp,mu_u,var_u,Lu,Kuu);
    pred(iter) = mu;        % Store prediction
    vari(iter) = var;
    yTest(iter)= yTrue;
    iTest(iter)= i_sNew;
    iter = iter + 1;
end
timer = toc;
t_run = timer/iter;
fprintf('Number of inducing points:     %i\n',Mu);
fprintf('Elapsed time:           total: %.3f s \n',timer);
fprintf('                per iteration: %f ms \n',t_run/1e-3);

%% scale back up
%{
% X
xTrain = xTrain.*sig_X' + mu_X';
f      = f.*sig_X + mu_X;
s      = s.*sig_X + mu_X;
loop   = loop.*sig_X + mu_X;
u      = u.*sig_X + mu_X;

%Y
yTrain = yTrain.*sig_Y + mu_Y;
mu_s   = mu_s.*sig_Y + mu_Y;
yf     = yf.*sig_Y + mu_Y;
pred   = pred.*sig_Y + mu_Y;
yTest  = yTest.*sig_Y + mu_Y;
var_s  = var_s.*sig_Y + mu_Y;
vari   = vari.*sig_Y + mu_Y;
yloop  = yloop.*sig_Y + mu_Y;
sn_old = sn;
sn     = sqrt(sn.^2*sig_Y);
%}

%% Results
fSize = 12;
resultsIFITC = figure(2);clf(resultsIFITC);
%{
sphandle(1,1) = subplot(2,1,1);
hold on
ha(1) = scatter(T(1,i_f),yf(:,1),'xb');
%ha(2).MarkerFaceAlpha = .6;
%ha(2).MarkerEdgeAlpha = .6;
%ha(1) = plot(xTrain(1,i_plot),yTrue(1,i_plot),'-k','LineWidth',1.5);
ha(2) = plot(T(1,i_s),mu_s,'r','LineWidth',1.5);
ha(3) = plot(T(1,i_s),mu_s + 2*sqrt(diag(var_s+ sn^2)),'k');
plot(T(1,i_s),mu_s - 2*sqrt(diag(var_s+ sn^2)),'k');
%ha(2) = scatter(u_old(:,1),zeros(size(u,1),1),ones(size(u,1),1)*10,'ok','filled');
legend(ha,'Initial data','Predicted mean',...
    'Predictive var.','Interpreter','Latex','FontSize',fSize);
title('Incremental FITC - Bijl2015','Interpreter','Latex','FontSize',fSize+8)
ylabel('y','Interpreter','Latex','FontSize',fSize+4)
hold off
clear ha
%}
sphandle(1,1) = subplot(1,1,1);
hold on
han(1) = scatter(T(1,i_f),yf(:,1),'xk');
han(1).MarkerFaceAlpha = .6;
han(1).MarkerEdgeAlpha = .6;
han(2) = scatter(T(1,i_loop),yloop(:,1),'xb');
han(3) = plot(iTest*Ts,pred,'r','LineWidth',1.5);
%scatter(u(:,1),zeros(Mu,1))
han(4) = plot(iTest*Ts,pred + 2*sqrt(vari+sn^2),'k');
plot(iTest*Ts,pred - 2*sqrt(vari+sn^2),'k');
%legend(han,'Initial data','Incremental data','t+1 predictions',...
%    'Predictive var.','Interpreter','Latex','FontSize',fSize);
ylabel('y','Interpreter','Latex','FontSize',fSize+4)
xlabel('t (s)','Interpreter','Latex','FontSize',fSize+4)
title('Incremental FITC - Bijl2015','Interpreter','Latex','FontSize',fSize+8)
hold off
clear ha han
[resultsIFITC,sphandle] = subplots(resultsIFITC,sphandle);

%% Error
error = rms(mu_s' - yTrain(1,i_s));
fprintf('RMS error :              FITC: %f \n',error)

error = rms(pred - yTest);
fprintf('             Incremental FITC: %f \n',error)

error = errorMeasure(yTest,pred);
fprintf('nRMS error:  Incremental FITC: %f \n',error)


%% Clear memory
%clear error fSize f s mu_s pred vari yloop

%% Run other scripts
%I_SSGP_LOOP
SSGP_Batch