%clear all, clc,

hyperparamUpdate = 0;  % Optimize hyperparameters [yes(1)/no(0)]
spectPointUpdate = 0;  % Optimize spectral points [yes(1)/no(0)]
D = 50;                % Number of random features

saveFig = 0;
%addpath('C:\Users\wout7\OneDrive - student.utwente.nl\ME - Master\Thesis\Data\TFlex\Training')

fprintf('  ----  Sparse Spectrum GP  ----  \n')

%% Load dataset:
ts = 1/1000;
% Use .Dat file or simulation data
useDat = 1;           % [1] - .Dat file; [0] - simulation data

if useDat == 0
    N        = length(SimulinkRealTime.utils.getFileScopeData('TRAIN.DAT').data)
    interval = 20/ts:N;
    DATA  = SimulinkRealTime.utils.getFileScopeData('TRAIN.DAT').data(:,:);
    xTrain = DATA(:,[1,2,3]);
    yTrain = DATA(:,4);
    %yTrain(:,2) = DATA(:,4);
else
    xTrain = squeeze(xTraining(:,1,:))';
    xTrain = xTraining;
    yTrain = yTraining(:);
    N = length(xTrain);
    interval = 1:N;
end

[ghost, dof] = size(xTrain);   % Training input dimension 
[ghost,   Q] = size(yTrain);   % Number of latent functions
yTrain  = yTrain(interval,:)';
xTrain  = xTrain(interval,:)';
%xSp     = xTrain;
N       = size(xTrain,2);      % Length of signal
T       = [[0:N-1]*ts]';        % Time vector

%Normalize data
%{
% X
mu_X   = mean(xTrain');
sig_X  = std(xTrain');
%xTrain = ((xTrain' - mu_X) ./ sig_X)';
%xSp    = ((xSp' - mu_X) ./ sig_X)';
%xSp(:,1:3) = [];

% Y
mu_Y   = mean(yTrain');
sig_Y  = std(yTrain');
%yTrain = ((yTrain' - mu_Y) ./ sig_Y)';
%}

%% (Hyper)parameters 
%Hyperparameters 
sn   = [ones(Q,1)];          % Noise variance
sf   = [ones(Q,1)];           % Signal variance
l    = [ones(Q,dof)];   % characteristic lengthscale

% Hyperparameters DoF 1
sf = 258.12;
sn = 1.3352;
l  = [0.87 2.63, 3587.69]; 

%Combine into 1 vector
hyp  = [l,sf,sn];

%% Data selection (intial)
N_train  = 2001;
xLim     = [1,30];
N_xLim   = (xLim(2)-xLim(1))/ts;
i_f = xLim(1)/ts + round(linspace(1,N_xLim,N_train));
%i_f = [10/ts:5:20/ts];
i_s = i_f;
i_loop = [1:N-100];
%i_loop = [1:50000];

f      = xTrain(:,i_f)';
s      = xTrain(:,i_s)';
loop   = xTrain(:,i_loop)';

yf      = yTrain(:,i_f)';
ys      = yTrain(:,i_s)';
yloop   = yTrain(:,i_loop)';

%% Initial s, R and b
s_r  = randn(D,dof);    % Spectral points
s_r0 = s_r;

%% Hyperparameter optimization
options = optimset;
options.Display = 'final';
options.TolFun = 1e-9;
options.TolX = 1e-9;
options.MaxIter = 1000;
lb = zeros(1,length(hyp));
if hyperparamUpdate == 1
    fprintf('Optimizing hyperparameters...\n');
    %[hyp nlml] = fminsearch(@(hyp) nlml_HypSSGP(hyp,f,yf,length(f),D,RAND,n),[hyp],options);
    for kk = 1:Q
        [hyp(kk,:) nlml] = fmincon(@(hyp) nlml_HypSSGP(hyp,f,yf(:,kk),length(f),D,s_r,dof),hyp(kk,:),[],[],[],[],lb,[],[],options);
    end
end

%% Optimize spectral points
RAND = zeros(Q,D,dof);
% Copy spectral points
for jj = 1:Q
    RAND(jj,:,:) = s_r;
end

if spectPointUpdate == 1
    fprintf('Optimizing spectral points...\n');
    options = optimset;
    options.Display = 'final';
    options.MaxIter = 10000;
    %[RAND nlml] = fminsearch(@(RAND) nlml_HypSSGP(hyp,f,yf,length(f),D,RAND,n),[RAND(1:D,:)],options);
    [RAND(Q,:,:) nlml] = fmincon(@(RAND) nlml_HypSSGP(hyp(1,:),f,yf(:,1),length(f),D,RAND,dof),squeeze(RAND(Q,:,:)),[],[],[],[],[],[],[],options);
    %{
    figure(510),clf(510);
    subplot(1,2,1)
    RAND_0 = RAND_0(1:D,:);
    hist(RAND_0(:))
    title('Before spectral optimization')
    
    subplot(1,2,2)
    RAND = RAND(1:D,:);
    hist(RAND(:))
    title('After spectral optimization')
    %}
end

% Show hyperparameters
l  = hyp(1:Q,1:dof);
sf = hyp(1:Q,dof+1);
sn = hyp(1:Q,dof+2);

fprintf('\n%% Hyperparameters\n')

fprintf('sf = [');
fprintf('%1.2f, ',sf(1:end-1,:));
fprintf('%1.2f',sf(end,:))
fprintf("]'; \n");

fprintf('sn = [');
fprintf('%1.2f, ',sn(1:end-1,:));
fprintf('%1.2f',sn(end,:))
fprintf("]'; \n");

fprintf('l  = [')
for jj = 1:Q
    fprintf('%1.2f, ',l(jj,1:end-1))
    fprintf('%1.2f',l(jj,end))
    if jj ~=Q
        fprintf('\n      ')
    end
end
fprintf(']; \n')

%% I-SSGP (fist part)

%{
i_f = i_loop;
i_s = i_f;
f  = xTrain(:,i_f)';
s  = xTrain(:,i_s)';
yf = yTrain(:,i_f)';
ys = yTrain(:,i_s)';
%}


% Preallocate vectors and matrices
mu_s   = zeros(length(i_s),Q);
var_s  = zeros(length(i_s),Q);
yTest  = zeros(length(i_loop),Q);
iTest  = zeros(length(i_loop),1);
pred   = zeros(length(i_loop),Q);
var    = zeros(length(i_loop),1);
vari   = zeros(length(i_loop),Q);

w    = zeros(2*D,Q);
b    = zeros(2*D,Q);
v    = zeros(2*D,Q);
phi  = zeros(2*D,1);

%Initialize vector and matrices
R     = zeros(Q,2*D,2*D);
SIGMA = zeros(Q,D,dof);
for kk = 1:Q
    R(kk,:,:)     = eye(2*D,2*D).*sn(kk).^2;
    SIGMA(kk,:,:) = squeeze(RAND(kk,:,:)).*(1./l(kk,:));
end

% Training Loop
for ii = 1:length(i_f)
    s_n   = f(ii,:);
    ys_n  = yf(ii,:);
    for jj = 1:Q
        sigma = squeeze(SIGMA(jj,:,:));
        phi = sf(jj)./sqrt(D) .*[cos(sigma*s_n')',...
                                 sin(sigma*s_n')']';
        %Update posterior
        b(:,jj)   =  b(:,jj) + phi*ys_n(:,jj);
        R(jj,:,:) = cholupdate(squeeze(R(jj,:,:)),phi);
        w(:,jj)   = solve_chol(squeeze(R(jj,:,:)),b(:,jj));
    end
end

%Prediction loop
iter = 1;
for ii = 1:length(i_s)
    s_n   = s(ii,:);
    ys_n  = ys(ii,:);
    for jj = 1:Q
        sigma = squeeze(SIGMA(jj,:,:));
        phi   = sf(jj)./sqrt(D) .*[cos(sigma*s_n')',...
                                   sin(sigma*s_n')']';
        %Prediction
        mu_s(iter,jj)   = dot(w(:,jj),phi);
        v               = squeeze(R(jj,:,:))'\phi;
        var_s(iter,jj)  = sn(jj).^2.*(1+dot(v,v));
    end
    iter = iter + 1;
end

%
%% True loop
%Prediction loop
tic;
iter = 1;
for ii = i_loop
    % New data
    i_sNew = ii+1;
    sNew   = xTrain(:,i_sNew)';    % New test point  
    %sNew   = xSetpoint(:,i_sNew)';   % New test point (from setpoint)
    yTrue  = yTrain(:,i_sNew)';     % Such that we can compare later

    fp  = xTrain(:,ii)';    % New training point
    yfp = yTrain(:,ii)';    % New training point
    
    for jj = 1:Q
        sigma = squeeze(SIGMA(jj,:,:));
        
        %    s_n   = s(jj,:);
        %    ys_n  = ys(jj,:);
        phi = sf(jj)./sqrt(D) .*[cos(sigma*sNew')',...
                                 sin(sigma*sNew')']';
        %Prediction
        pred(iter,jj)   = dot(w(:,jj),phi);
        v               = squeeze(R(jj,:,:))'\phi;
        vari(iter,jj)   = sn(jj).^2.*(1+dot(v,v));
                
        %Update posterior
        phi = sf(jj)./sqrt(D) .*[cos(sigma*fp')',...
                                 sin(sigma*fp')']';
        b(:,jj)   =  b(:,jj) + phi*yfp(1,jj);
        R(jj,:,:) = cholupdate(squeeze(R(jj,:,:)),phi);
        w(:,jj)   = solve_chol(squeeze(R(jj,:,:)),b(:,jj));
    end
    yTest(iter,:)  = yTrue;
    iTest(iter,1)  = i_sNew;
    iter = iter + 1;
end
timer = toc;
t_run = timer/iter;
fprintf('Number of features:            %i\n',D);
fprintf('Elapsed time:           total: %.3f s \n',timer);
fprintf('                per iteration: %f ms \n',t_run/1e-3);
iTest = iTest + 60/ts;

%}
%% Results
clear ha
%figure settings
colors = [0,      0.4470, 0.7410;
          0.8500, 0.3250, 0.0980;
          0.9290, 0.6940, 0.1250;
          0.4940, 0.1840, 0.5560];
fontSize   = 8;
labelSize  = 11;
legendSize = 8;

results = figure(3);clf(results);
%{
sphandle(1,1) = subplot(2,1,1);
hold on
ha(1) = scatter(T(1,i_f),yf(:,1),'xb');
%ha(2).MarkerFaceAlpha = .6;
%ha(2).MarkerEdgeAlpha = .6;
%ha(1) = plot(xTrain(1,i_plot),yTrue(1,i_plot),'-k','LineWidth',1.5);
ha(2) = plot(T(1,i_s),mu_s,'r','LineWidth',1.5);
ha(3) = plot(T(1,i_s),mu_s + 2*sqrt(var_s+ sn^2),'k');
plot(T(1,i_s),mu_s - 2*sqrt(var_s+ sn^2),'k');
%ha(2) = scatter(u_old(:,1),zeros(size(u,1),1),ones(size(u,1),1)*10,'ok','filled');
legend(ha,'Initial data','Predicted mean',...
    'Predictive var.','Interpreter','Latex','FontSize',fSize);
title('Incremental Sparse Spectrum GP - Gijsberts2013','Interpreter','Latex','FontSize',fSize+8)
ylabel('y','Interpreter','Latex','FontSize',fSize+4)
hold off
clear ha
%}
set(gca,'FontSize',fontSize);
for jj = 1:Q
ha(1,1) = subplot(1,1,1);
hold on
han(2) = scatter(T(i_f,1),yf(:,jj),'xk');
han(1) = plot(iTest*ts,yloop(:,jj),'-','LineWidth',0.1);
han(3) = plot(iTest*ts,pred(:,jj),'-','LineWidth',1);
%han(4) = plot(iTest*ts,pred + 2*sqrt(vari+sn^2),':k','LineWidth',0.01);
%plot(iTest*ts,pred - 2*sqrt(vari+sn^2),':k','LineWidth',0.01);
%legend(han,'Initial data','Incremental data','t+1 predictions',...
%    'Predictive var.','Interpreter','Latex','FontSize',fSize);
ylabel('(mA)','Interpreter','Latex','FontSize',labelSize)
xlabel('t (s)','Interpreter','Latex','FontSize',labelSize)
%title('Incremental Sparse Spectrum GP - Gijsberts2013','Interpreter','Latex','FontSize',fSize+8)
%xlim([60 95])
%ylim([-22 30])
%legend(han([1,3,4]),'$u_\mathrm{FB}$','$\mu_{*,t+1}$','$\Sigma_{*,t+1}$','Interpreter','Latex','FontSize',labelSize);
legend(han([1,3]),'$u_\mathrm{FB}$','$\mu_{*,t+1}$','Interpreter','Latex','FontSize',labelSize);
end
hold off

[results,ha] = subplots(results,ha);
set(gcf,'PaperSize',[8.4 8.4*3/4+0.1],'PaperPosition',[0 0.2 8.4 8.4*3/4+0.2])

%% Error
error = rms(mu_s' - yTrain(Q,i_s));
fprintf('RMS error :              SSGP: %f \n',error)

error = rms(pred - yTest);
fprintf('             Incremental SSGP: %f \n',error)

error = errorMeasure(yTest,pred);
fprintf('nRMS error:  Incremental SSGP: %f \n',error)
%}

% Show hyperparameters
fprintf('\n%% Hyperparameters DoF 1\n')
fprintf('sf = %.2f;\n',sf)
fprintf('sn = %.4f;\n',sn)
fprintf('l  = [')
fprintf('%1.2f ',l(1:end-1))
fprintf('     %1.2f',l(end))
fprintf(']; \n')


%% Save Figure
if saveFig == 1
    saveas(results,fullfile(pwd,'Images','TwinISSGP.pdf'))
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end
