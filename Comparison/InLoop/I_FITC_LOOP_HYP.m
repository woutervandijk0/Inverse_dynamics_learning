clear all, clc,
fprintf('  ----  Incremental FITC - Bijl2015  ----  \n')

%% Load dataset:
dataID = 'TFlexADRC_RN20.mat';
%dataID = 'TFlexADRC_RN20_Isp.mat';
%dataID = 'sarcos_inv.mat';
%dataID = 'TFlex1D5G.mat';
%dataID = 'TFlex1D-2.mat'
%dataID = 'sarcos_inv.mat';
%dataID = 'BaxterRhythmic.mat';
%dataID = 'BaxterRand.mat';
[xTrain, yTrain, Ts] = selectData(dataID,'fig',false);
if strcmp( dataID,'TFlexADRC_RN20_Isp.mat')
    xTrain(1:3,:) = [];
    yTrain(end-3:3,:) = [];
end

[dof, N] = size(xTrain');
yTrain  = yTrain(:,1)';
xTrain  = xTrain';
xSp = xTrain;
%xSp(3,:)  = movmean(xTrain(3,:),10);

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
sn  = 1;          % Noise variance
sf   = 0.5;           % Signal variance
l    = [ones(1,dof)];   % characteristic lengthscale
%Combine into 1 vector
hyp  = [sf,l];

%overwrite hyperparam
sn  = 0.0738;
hyp = [2.9542    0.5850   18.0805    1.8132];
%sn  = 0.1322;
%hyp = [1.0094    1.4140   15.5060    4.6677];

%% Data selection (intial)
i_f = [1:500];
i_u = [1:5:i_f(end)];
i_s = i_f;
i_loop  = [i_f(end)+1:10000];
i_loop  = [1000+1:10000];

f  = xTrain(:,i_f)';
u  = xTrain(:,i_u)';
s  = xTrain(:,i_s)';
loop   = xTrain(:,i_loop)';

yf = yTrain(:,i_f)';
ys = yTrain(:,i_s)';
yloop   = yTrain(:,i_loop)';

Mf  = length(i_f);
%% Hyperparameter optimization
%
options = optimset;
options.Display = 'final';
options.MaxIter = 500;
%[nlml] = nlml_I_FITC(hyp, sn, u, f, yf, 'VFE')
%  [hyp_sn nlml] = fminsearch(@(hyp) nlml_I_FITC(hyp, u, f, yf, 'VFE'),[hyp,sn],options);
%  hyp = abs(hyp_sn(1:end-1));
%  sn  = abs(hyp_sn(end));
sn2 = sn^2;
%}

options.MaxIter = 5;

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
Nkeep = 40;
Nremove = size(u,1)-(Nkeep-1);
[u,Kuu,Lu,mu_u,var_u,Mu] = updateInducing(hyp,sn,u,mu_u,var_u,Kuu,u(Nremove,:),Nremove);

HYP = zeros(length(i_loop)+1,4);
SN  = zeros(length(i_loop)+1,1);

% Initialize inducing points
x = u;
M = Nkeep-1;
B = ones(M,1).*x(1);
for i = 2:dof
    B = [B,ones(M,1).*x(i)];
end
n       = 1;       % 
NORM    = -(ones(M,M)-eye(M));    %Initial matrix with norms
minNorm = 0;    % Min. norm in set of inducing points


fprintf('Expected simulation time: %.3f seconds ...\n',length(i_loop)*1e-3)
beta = 0.1;
Mf   = 500;
uSamp = floor(Mf/10)

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
    
    fp  = xTrain(:,jj)';    % New training point
    yfp = yTrain(:,jj)';    % New training point
    
    %add to set of inducing points?
    %
    d_new = sqrt(sum((B-fp).^2,2));      % Norms between new sample and inducing points
    d_min = min(d_new);                  % Minimal norm for new sample
    if (d_min > minNorm)
        d_new(n)  = 0;          % For zero on diagonal
        NORM(n,:) = d_new';     % 
        NORM(:,n) = d_new ;     % 
        A = B;
        B(n,:)   = fp;          % Replace inducing point with new sample
        %Find new min. norm between inducing points
        [minNorm, n] = min(min(NORM+eye(M)*1e6));
        
        newInduce = true;
        [u,Kuu,Lu,mu_u,var_u] = updateInducingV2(hyp,sn,u,mu_u,var_u,Kuu,fp,n);
        %disp('U updated')
    else
        [u,Kuu,Lu,mu_u,var_u] = updateInducingV2(hyp,sn,u,mu_u,var_u,Kuu,fp,Nkeep);
    end
    NORM = NORM*0.99;
    %}
    [u,Kuu,Lu,mu_u,var_u] = updateInducingV2(hyp,sn,u,mu_u,var_u,Kuu,uNew,Nkeep);

    %{
    if (mod(jj,50)==0) && (iter>2)
        
        i_fNew = [(jj-(Mf)):jj];
        fNew  = xTrain(:,i_fNew)';
        yfNew = yTrain(:,i_fNew)';
        
        [hyp_sn nlml] = fminsearch(@(hyp) nlml_I_FITC(hyp, u, fNew, yfNew, 'VFE'),[hyp,sn],options);
        hyp = (1-beta)*hyp + beta*abs(hyp_sn(1:end-1));
        sn  = (1-beta)*sn  + beta*abs(hyp_sn(end));
        sn2 = sn^2;
        HYP(iter,:) = hyp;
        SN(iter,1) = sn;
    end
    %}
        
    
    
    % Update inducing points
    %if mod(jj,10) == 0
    %    [u,Kuu,Lu,mu_u,var_u,Mu] = updateInducing(hyp,sn,u,mu_u,var_u,Kuu,xTrain(:,jj-500:jj)',1);
    %end
    %if mod(jj,1) == 0
    %    [u,Kuu,Lu,mu_u,var_u,Mu] = updateInducing(hyp,sn,u,mu_u,var_u,Kuu,uNew,0);
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
%
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
%sn     = sqrt(sn.^2*sig_Y);
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
legend(han,'Initial data','Incremental data','t+1 predictions',...
    'Predictive var.','Interpreter','Latex','FontSize',fSize);
ylabel('y','Interpreter','Latex','FontSize',fSize+4)
xlabel('t (s)','Interpreter','Latex','FontSize',fSize+4)
title('Incremental FITC - Bijl2015','Interpreter','Latex','FontSize',fSize+8)
hold off
clear ha han
[resultsIFITC,sphandle] = subplots(resultsIFITC,sphandle);

%% Hyperparameters
[iPlot ~] = find(HYP(:,1)~=0);
figure(444),clf(444)
subplot(2,1,1)
plot(HYP(iPlot,:))
subplot(2,1,2)
plot(SN(iPlot,1))

%% Error
error = rms(mu_s' - yTrain(1,i_s));
fprintf('RMS error :              FITC: %f \n',error)

error = rms(pred - yTest);
fprintf('             Incremental FITC: %f \n',error)

error = errorMeasure(yTrain(1,i_loop+1),pred);
fprintf('nRMS error:  Incremental FITC: %f \n',error)


%% Clear memory
%clear error fSize f s mu_s pred vari yloop

%% Run other scripts
%I_SSGP_LOOP
%SSGP_LOOP