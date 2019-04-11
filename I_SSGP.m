close all, clear all

%% Select and open Dataset ('Default' opens file explorer)
dataID = 'TFlex1D-2.mat';
%dataID = 'TFlex1D5G.mat';
dataID = 'TFlexADRC_RN20.mat';
dataID = 'DoublePendulum.mat'

%% Settings 
param_update   =  false;  % Update hyperparameters in the loop (true/false)
loadSetpoint   =  true;   % 
compareWTrue   =  false;  % Compare with real data (only for periodic datasets)
loadParams     =  true;   % Load hyper parameters from previous run
saveParams     =  true;   %
manualParams   =  false;  % Manualy set hyperparams
fromScratch    =  true;  % Start with clean sheet
onlyPredict    =  1e9;   % Only predict after the nth iteration

D = 100;    % Number of random features
Z = 500;    % Size of floating frame
maxIter    = 1e4;   % Max number of iterations
trainIter  = 1;     % Number of Posterior updates per new sample
trainSteps = 10;
numDescent = 5;     % Number of fmincon iterations
resamp = 1;

%Learning Rates:
alpha = 1;      % Update posterior
beta  = 0.5;      % Hyperparameters
kappa = 1;      % Prediction

%% Load dataset & Normalize 
% Load
[X,Y,ts,N_io] = selectData('dataset',dataID,'fig',true,'figNum',1);

n = size(X,2);      % Number of inputs
Q = size(Y,2);      % Number of latent functions

% Normalize by limits of system;
mu_X  = mean(X);
sig_X = std(X);
X = (X - mu_X) ./ sig_X;

%Load setpoint
if loadSetpoint == true
    Xsp = loadSp(dataID);
    Xsp = (Xsp - mu_X) ./ sig_X;
else
    Xsp = X;
end

% Normalize
mu_Y  = mean(Y);
sig_Y = std(Y);
Y = (Y - mu_Y) ./ sig_Y;
%Y = movmean(Y,30);

%
t_learn = 30;
X = X(t_learn/ts:end,:);
Y = Y(t_learn/ts:end,:);
Xsp = Xsp(t_learn/ts:end,:);
%}
%% Hyperparam optimization settings
options = optimset();
options.Display = 'none';
options.MaxIter = numDescent;
%options.Hessian = 'off';
%options.Method = 'sqp';
%active-set | interior-point | interior-point-convex | levenberg-marquardt | ...
                           %sqp | trust-region-dogleg | trust-region-reflective
%options.TolFun  = 1e-3;
%options.UseParallel = true

%% Hyperparameters (default unit)
% Likelihood
sn      =   ones(Q,1);       % Std of likelihood function
sn      =   ones(Q,1)*1;
% Covariance
sf      =   ones(Q,1)*0.01;        % Std covariance (at t=0, 1)
ell     =   ones(Q,n)*0.01;       % Length scales (at t=0, 1)

if loadParams == true
        [sn, sf, ell] = loadHyperparams(dataID,false);
%        ell = ell'; sf = sf'; sn = sn'; %Use transpose
        disp([char(10),'Hyperparams loaded for: ',dataID]) 
        disp(['ell: ',num2str(ell(1,:))])
        disp(['sf : ',num2str(sf(1:Q)')]);
        disp(['sn : ',num2str(sn(1:Q)'),char(10)]);
end
if manualParams == true
    switch (dataID)
        case 'TFlex1D5G.mat'
            sf  = 1.844;
            sn  = 5.0000;
            ell = [1.192    0.1891    0.3826];
        case 'TFlex1D-2.mat'
            sn  = 2.1108;
            sf  = 5.5283;
            ell = [-9    0.0516    9.8040];
        case 'TFlexADRC_RN20.mat'
            sn = 2;
            sf = 1.9831;
            ell = [0.3994    0.1347    0.6647];
    end
    disp('Hyperparameters overwritten with: ')
    disp(['ell: ',num2str(ell(1,:))])
    disp(['sf : ',num2str(sf(1:Q)')]);
    disp(['sn : ',num2str(sn(1:Q)'),char(10)]);
end

%sf = 5;
%Combine to 1 vector;
disp('Final hyperparameters: ')
disp(['ell: ',num2str(ell(1,:))])
disp(['sf : ',num2str(sf(1:Q)')]);
disp(['sn : ',num2str(sn(1:Q)'),char(10)]);

hyp     =   abs([ell(:,1:n),sf]);

%% Run incremental sparse spectrum GP
% Preallocate vectors and matrices
if fromScratch == true
    numIter  = min(length(X),maxIter);
    muPred   = zeros(numIter,Q);
    yhat     = zeros(numIter,Q);
    yhatSp   = zeros(numIter,Q);
    s2       = zeros(numIter,Q);
    s2Sp     = zeros(numIter,Q);
    nlml     = zeros(numIter,1);
    HYP      = zeros(Q,numIter,n+1);
    phi_x    = zeros(Z,Z);
    
    w    = zeros(2*D,Q);
    b    = zeros(2*D,Q);
    v    = zeros(2*D,Q);
    phi  = zeros(2*D,Q);
    
    RAND  = randn(D,n);
    R = zeros(Q,2*D,2*D);
    for i = 1:Q
        R(i,:,:) = eye(2*D,2*D)*sn(Q);
        SIGMA(i,1:D,1:n) = RAND.*hyp(i,1:n);
    end
    sqrtD =  sqrt(D);
    sn2 = sn.^2;
end
iter = Z;

%Start loop
tic;
for ii = Z:numIter
    %Prediction with setpoint
    for i = 1:Q
        phi      = sf(i)./sqrtD .*[cos(squeeze(SIGMA(i,:,:))*Xsp(ii,1:n)')',...
            sin(squeeze(SIGMA(i,:,:))*Xsp(ii,1:n)')']';
        yhatSp(iter,i) = (1-kappa).*yhatSp(iter-1,i) + kappa*dot(w(:,i),phi);
        v(:,i)        = squeeze(R(i,:,:))'\phi;
        s2Sp(iter,i)   = sn2(i).*(1+dot(v(:,i),v(:,i)));
        
        % When setpoint and measured data is different
        if loadSetpoint == true
            phi      = sf(i)./sqrtD .*[cos(squeeze(SIGMA(i,:,:))*X(ii,1:n)')',...
                sin(squeeze(SIGMA(i,:,:))*X(ii,1:n)')']';
        end
        yhat(iter,i) = (1-kappa).*yhat(iter-1,i) + kappa*dot(w(:,i),phi);
        v(:,i)        = squeeze(R(i,:,:))'\phi;
        s2(iter)   = sn2(i).*(1+dot(v(:,i),v(:,i)));
        
        % Hyperparameter optimization
        if param_update == true && iter >= 1 && mod(iter,trainSteps) == 0
            y    = Y((ii-Z+1):ii,i);
            x    = X((ii-Z+1):ii,1:n);
            hyp_opt = hyp(i,:);
            [hyp(i,:) nlml(iter)] = fminsearch(@(hyp_opt) calcNLML(hyp_opt,sn2(i),x,y,Z,D,RAND,n),hyp_opt,options);
            hyp(i,:) = (1-beta).*hyp_opt + beta.*hyp(i,:);
            HYP(i,iter,:) = hyp(i,1:n+1);     %Store current hyperparams
            sf(i)    = hyp(i,end);
            SIGMA(i,1:D,1:n) = RAND.*hyp(i,1:n);
        end
        if iter < onlyPredict
            %Update posterior
            for ij = 1:trainIter
                b(:,i) =  b(:,i) + phi*Y(ii,i);
                R(i,:,:) = cholupdate(squeeze(R(i,:,:)),phi);
                w(:,i) = (1-alpha).*w(:,i) + alpha.*(squeeze(R(i,:,:))\(squeeze(R(i,:,:))'\b(:,i)));
            end
        end
    end
    
    % show progress
    if mod(ii,round((numIter-Z)/10)) == 0
        disp([num2str(round(ii/numIter*100)),' %'])
    end
    iter = iter+1;
end
toc;
t_run = toc/(ii-Z);
disp([char(10),"Elapsed time per iteration: ",num2str(t_run)])

%% Scale back up
Y      =      Y.*sig_Y + mu_Y;
yhatSp = yhatSp.*sig_Y + mu_Y;
yhat   =   yhat.*sig_Y + mu_Y;
s2Sp   =   s2Sp.*sig_Y + mu_Y;
s2     =     s2.*sig_Y + mu_Y;

%% Plot results
muPred   = yhat(Z:end,:);
muPredSp = yhatSp(Z:end,:);
i_plot   = Z:1:ii;
t        = i_plot*ts;

% Hyperparams
if param_update == true
    figure(555),clf(555)
    fm = 4/5;
    for i = 1:Q
        subplot(1,Q,i);
        %sn_vec(ii) = HYP(ii).hyp.lik;
        hyp_v = squeeze(HYP(i,:,:));
        hyp_v(find(hyp_v==0)) = [];
        hyp_v = reshape(hyp_v,[length(hyp_v)/(n+1),n+1]);
        hold on
        plot(t(1:trainSteps:end),hyp_v,'LineWidth',1.5);
        hyp_mean(i,:) = mean(hyp_v(round(length(hyp_v)*fm):end,:));
        plot(t([1,end]),[hyp_mean(i,:); hyp_mean(i,:)],'--k');
        hold off
        xlabel('time (s)');
        legend('$l_1$ $(\theta)$','$l_2$ $(\dot{\theta})$','$l_3$ $(\ddot{\theta})$','$\sigma_s$','Interpreter','Latex');
        set(gcf,'Color','w')
        title('Hyperparameters')
    end
    
    %Store hyperparams in .mat file
    if saveParams == true
        sn  = sn;
        ell = hyp_mean(:,1:end-1);
        sf  = hyp_mean(:,end);
        folderName = 'Results\hyperparamSettings\';
        paramID = [dataID(1:end-4),'_param.mat'];
        save([folderName,paramID],'sn','ell','sf')
    end
end
%%
% figure(555),clf(555)
% hold on
% plot(t,Y(i_plot,1))
% plot(t,muPred','LineWidth',2)
% plot(t,muPred'+sqrt(s2'),'k')
% plot(t,muPred'-sqrt(s2'),'k')
% hold off

for i = 1:Q
    figure(10*i+i),clf(10*i+i);
    ax71 = subplot(6,1,1);
    hold on
    plot(t,X(i_plot,i)','k')
    plot(t,Xsp(i_plot,i)','r')
    legend('Measured','Setpoint')
    ylabel('normalized pos.')
    title(['Latent function ',num2str(i)])
    hold off
    
    ax72 = subplot(6,1,2);
    hold on
    plot(t,X(i_plot,i+n/3)','k')
    plot(t,Xsp(i_plot,i+n/3)','r')
    legend('Measured','Setpoint')
    ylabel('normalized vel.')
    hold off
    
    ax73 = subplot(6,1,3);
    hold on
    plot(t,X(i_plot,i+n*2/3)','k')
    plot(t,Xsp(i_plot,i+n*2/3)','r')
    legend('Measured','Setpoint')
    ylabel('normalized acc.')
    hold off
    
    ax74 = subplot(6,1,4:6);
    hold on
    plot(t,Y(i_plot,i)','k','LineWidth',1.5);               % Measured signal
    plot(t,muPred(i_plot-Z+1,i)','--b','LineWidth',1.5);    % Predictions from measurements
    plot(t,muPredSp(i_plot-Z+1,i)',':r','LineWidth',1.5);   % Predictions from setpoint
    %Plot variances
    %plot(t,muPred(i_plot-Z+1,i)'+sqrt(s2(i_plot-Z+1,i)'),'b')
    %plot(t,muPredSp(i_plot-Z+1,i)'+sqrt(s2Sp(i_plot-Z+1,i)'),'r')
    %plot(t,muPred(i_plot-Z+1,i)'-sqrt(s2(i_plot-Z+1,i)'),'b')
    %plot(t,muPredSp(i_plot-Z+1,i)'-sqrt(s2Sp(i_plot-Z+1,i)'),'r')
    
    %Plot switch
    if onlyPredict < numIter
        plot([onlyPredict onlyPredict]*ts, [min(Y(i_plot-1,i)) max(Y(i_plot-1,i))],':k','LineWidth',1.5)
    end
    
    legend('Measured','\mu_{measure}','\mu_{setpoint}','\sigma_{measure}','\sigma_{setpoint}');
    xlabel('time (s)')
    ylabel('Current (mA)')
    hold off
    linkaxes([ax71,ax72,ax73,ax74],'x');
    
%     figure(150),clf(150)
%     hold on
%     plot(t,Y(i_plot)')
%     plot(t,muPred(i_plot-Z+1)','--k')
%     plot(t,muPredSp(i_plot-Z+1)',':m','LineWidth',1.5)
%     legend('Measured','pred. w. Meas.','pred. w. Set.')
%     xlabel('time (s)')
%     ylabel('Current (mA)')
%     hold off
end

%% Error measure
% Select data
i_end  = round((t(end)/2)/ts);
iEnd   = length(muPred);
iStart = iEnd-i_end;
shift = -1;
t_c  = t(iStart:iEnd);
Y_m  =   Y(iStart+Z+shift:iEnd+Z+shift,:);
X_m  =   X(iStart+Z+shift:iEnd+Z+shift,1);
X_sp = Xsp(iStart+Z+shift:iEnd+Z+shift,1);
%From measured data:
Y_p  = muPred(iStart:iEnd,:); 
s2_p = s2(iStart:iEnd,:);
%From setpoint:
Y_psp  = muPredSp(iStart:iEnd,:); 
s2_psp = s2(iStart:iEnd,:);

disp(' ');
disp(['t+1 predictions (from measurements):']);
NMSE = errorMeasure(Y_m,Y_p,'method','NMSE','show',true);
%MAE = errorMeasure(Y_m,Y_p,'method','MAE','show',true);
%MSE = errorMeasure(Y_m,Y_p,'method','MSE','show',true);
RMSE = errorMeasure(Y_m,Y_p,'method','RMSE','show',true);

disp(' ');
disp(['t+1 predictions (from setpoint):']);
NMSE = errorMeasure(Y_m,Y_psp,'method','NMSE','show',true);
%MAE = errorMeasure(Y_m,Y_psp,'method','MAE','show',true);
%MSE = errorMeasure(Y_m,Y_psp,'method','MSE','show',true);
RMSE = errorMeasure(Y_m,Y_psp,'method','RMSE','show',true);

figure(111),clf(111);
plot(t_c,Y_m','k')
hold on
plot(t_c,Y_p','--b')
plot(t_c,Y_psp',':r')
legend('Measured','pred. w. Meas.','pred. w. Set.');
xlabel('time (s)'); ylabel('Current (mA)')
title(['1-step ahead predictions    (',num2str(dataID),')'])
set(gcf,'Color','White')
hold off
%}
% Displacement vs current
figure(123),clf(123)
set(gcf,'Color','White')
sp1 = subplot(2,1,1);
plot(X_sp,Y_psp)
xlabel('$\theta_{sp}$','Interpreter','Latex','FontSize',15)
ylabel('$I_{sp}$ (mA)','Interpreter','Latex','FontSize',12)
title('Setpoint vs Predicted current')
legend('\theta_1','\theta_2');

sp2 = subplot(2,1,2);
plot(X_m,Y_m)
xlabel('$\theta_{m}$','Interpreter','Latex','FontSize',15)
ylabel('$I_{m}$ (mA)','Interpreter','Latex','FontSize',12)
title('Displacement vs Current (measured)')
linkaxes([sp1,sp2],'xy')

%%
%{
figure
ax1 = subplot(2,1,1);
hold on
plot(t,Y(i_plot,i)','k','LineWidth',1.5);               % Measured signal
plot(t,muPred(i_plot-Z+1,i)','--b','LineWidth',1.5);    % Predictions from measurements
plot(t,muPredSp(i_plot-Z+1,i)',':r','LineWidth',1.5);   % Predictions from setpoint
%Plot switch
if onlyPredict < numIter
    plot([onlyPredict onlyPredict]*ts, [min(Y(i_plot-1,i)) max(Y(i_plot-1,i))],':k','LineWidth',1.5)
end
legend('Measured','\mu_{measure}','\mu_{setpoint}','\sigma_{measure}','\sigma_{setpoint}');
xlabel('time (s)')
ylabel('Current (mA)')
hold off

ax2 = subplot(2,1,2);
hold on
plot(t(1:trainSteps:end),hyp,'LineWidth',1.5);
hyp_mean(i,:) = mean(hyp(round(length(hyp)*fm):end,:));
plot(t([1,end]),[hyp_mean(i,:); hyp_mean(i,:)],'--k');
hold off
xlabel('time (s)');
legend('$l_1$ $(\theta)$','$l_2$ $(\dot{\theta})$','$l_3$ $(\ddot{\theta})$','$\sigma_s$','Interpreter','Latex');
set(gcf,'Color','w')
hold off
linkaxes([ax1,ax2],'x');
%}

%{

figure(8),clf(8);

ax81 = subplot(3,1,1);
hold on
plot(t,X(i_plot,3)')
plot(t,Xsp(i_plot,3)','m')
legend('Measured','Setpoint')
ylabel('normalized acc.')
xlim([10.4 10.8])

hold off

ax82 = subplot(3,1,2);
hold on
plot(t,Y(i_plot)')
plot(t,muPred','--k')
plot(t,muPredSp',':m','LineWidth',1.5)
legend('Measured','pred. w. Meas.','pred. w. Set.')
ylabel('Current (mA)')
xlim([10.4 10.8])
hold off

mu_muPredSp  = mean(muPredSp);
sig_muPredSp = std(muPredSp);
muPredSp = (muPredSp - mu_muPredSp) ./ sig_muPredSp;

ax83 = subplot(3,1,3);
hold on
plot(t,muPredSp')
plot(t,muPredSp' - Xsp(i_plot,3)'*(1))
%plot(t,muPredSp'-Xsp(i_plot,2)'*(1002/2.4521))
xlim([10.4 10.8])
hold off
%}