close all, clear all

%% Select and open Dataset ('Default' opens file explorer)
dataID = 'TFlex1D-2.mat';
%dataID = 'TFlex1D5G.mat';
%dataID = 'TFlexADRC_RN20.mat';

%% Settings 
M = 100;    % Number of inducing points
Z = 500;    % Size of floating frame
Z_resamp   = 100;
maxIter    = 5e4;   % Max number of iterations
trainSteps = 100;
numDescent = 5;     % Number of fmincon iterations
resamp = 1;

%Power-EP
alpha = 1;      % VFE,  alpha = 0
                % SPEP, 0 < alpha < 1
                % FITC, alpha = 1

%Learning Rates:
beta  = 1;      % Hyperparameters
beta_min   = 0.001;
beta_reduc = 0.9999

%% Load dataset & Normalize 
% Load
[X,Y,ts,N_io] = selectData('dataset',dataID,'fig',true,'figNum',1);

dof = size(X,2);      % Number of inputs
Q = size(Y,2);      % Number of latent functions

% Normalize by limits of system;
mu_X  = mean(X);
sig_X = std(X);
mu_Y  = mean(Y);
sig_Y = std(Y);

% Normalize
%Y = (Y - mu_Y) ./ sig_Y;

xTrain = X;
yTrain = Y;

%{
t_learn = 50;
X = X(t_learn/ts:end,:);
Y = Y(t_learn/ts:end,:);
Xsp = Xsp(t_learn/ts:end,:);
%}
%% Hyperparam optimization settings
%options = optimset();
options.Display = 'none';
options.MaxIter = numDescent;


%% Hyperparameters (default unit)
% Likelihood
sn      =   ones(Q,1)*1;
% Covariance
sf      =   ones(Q,1)*1;        % Std covariance (at t=0, 1)
ell     =   ones(Q,dof)*1;       % Length scales (at t=0, 1)

hyp     =   [sf,ell(:,1:dof)];

%% Run incremental sparse spectrum GP
% Preallocate vectors and matrices
    numIter  = min(length(X),maxIter);
    muPred   = zeros(numIter,Q);
    yhat     = zeros(numIter,Q);
    yhatSp   = zeros(numIter,Q);
    s2       = zeros(numIter,Q);
    s2Sp     = zeros(numIter,Q);
    nlml     = zeros(numIter,Q);
    HYP      = zeros(Q,numIter,dof+1);
    sn2 = sn.^2;

iter = 1;%Z;
iterHypOpti = 0;

% Initialize inducing points
x = xTrain(1,:);
B = ones(M,1).*x(1);
for i = 2:dof
    B = [B,ones(M,1).*x(i)];
end
n       = 1;       % 
NORM    = -(ones(M,M)-eye(M));    %Initial matrix with norms
minNorm = 0;    % Min. norm in set of inducing points

%Start loop
tic;
for ii = Z:(numIter-1)
    %New data point
    x = (xTrain(ii,:) - mu_X) ./ sig_X;
    s = xTrain(ii+1,:);
    f = xTrain((ii-Z+1):ii,:);
    yf = yTrain((ii-Z+1):ii,:);
    err = yf;
    
    %add to set of inducing points?
    d_new = sqrt(sum((B-x).^2,2));      % Norms between new sample and inducing points
    d_min = min(d_new);                 % Minimal norm for new sample
    if (d_min > minNorm)
        d_new(n)  = 0;          % For zero on diagonal
        NORM(n,:) = d_new';     % 
        NORM(:,n) = d_new ;     % 
        A = B;
        B(n,:)   = x;             % Replace inducing point with new sample
        %Find new min. norm between inducing points
        [minNorm n] = min(min(NORM+eye(M)*1e6));
        newInduce = true;
    else
        newInduce = false;
    end
    
    %% Hyperparam update
%     hyp_opt = hyp;
%     if (newInduce == true) && (ii>Z)
%         %Build common terms
%         [LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs, Dff, LD, Kaa_old] = sgpBuildTerms(hyp,sn,f,yf',B,A,alpha);
%         %Predict
%         [ma,~,Saa] = predictSGP(hyp, A, LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs);         
%         [hyp nlml] = fminsearch(@(hyp) osgpNLML(hyp,sn,alpha,f,yf',A,B,Saa,ma,Kaa_old,err'),hyp_opt,options);
%     else
%         [hyp nlml] = fminsearch(@(hyp) sgpNLML(hyp,sn,alpha,f,yf',B,s,err',Z),hyp_opt,options);
%     end
%         HYP(1,iter,:) = hyp(1,1:dof+1);     %Store current hyperparams

    %Prediction
    if (newInduce == true) && (iter>1)
        %Build common terms
        [LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs, Dff, LD, Kaa_old] = sgpBuildTerms(hyp,sn,f,yf',B,A,alpha);
        %Predict
        [ma,~,Saa] = predictSGP(hyp, A, LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs);
        %Build common terms
        [La, Lb, LD, LSa, LDinv_c, Dff, Sainv_ma, LM, Q, LQ] = osgpBuildTerms(hyp,sn,f,yf',A,B,Saa,ma,Kaa_old,alpha);
        %Predict
        Kbs         = SEcov(B,s,hyp);
        [m(iter),var,Su] = predictOSGP(hyp, B, s, Lb, LD, LDinv_c, Kbs);
        
    else
        %Build common terms
        [LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs, Dff, LD, Kaa_old] = sgpBuildTerms(hyp,sn,f,yf',B,s,alpha);
        %Predict
        [mu,var,Su] = predictSGP(hyp, s, LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs); 
    end
    
%     f  = xTrain((ii-Z+1):ii,:);
%     yf = yTrain((ii-Z+1):ii,:);
%     err = yf;
%     s  = 
%     
%     
%     if iterHypOpti == 0
%         for i = 1:Q
%             if param_update == true && iter >= 1
%                 hyp_opt = hyp;
%                 [hyp nlml] = fminsearch(@(hyp) sgpNLML(hyp,sn,f,yf,b,s,alpha,err,Z),hyp,options);
%                 HYP(i,iter,:) = hyp(i,1:n+1);     %Store current hyperparams
%             end
%         end
%     else
%        	for i = 1:Q
%             if param_update == true && iter >= 1 && mod(iter,trainSteps) == 0
%                 hyp_opt = hyp;
%                 [hyp nlml] = fminsearch(@(hyp) osgpNLML(hyp,sn,alpha,f,yf,a,b,Saa,ma,Kaa_old,err),hyp_opt,options);
%                 HYP(i,iter,:) = hyp(i,1:n+1);     %Store current hyperparams
%             end
%         end
%     end
%     
%     % show progress
%     if mod(ii,round((numIter-Z)/10)) == 0
%         disp([num2str(round(ii/numIter*100)),' %'])
%     end
     iter = iter+1;
%     beta = beta*beta_reduc;
%     beta = max(beta,beta_min);
end
toc;
t_run = toc/(ii-Z);
disp([char(10),"Elapsed time per iteration: ",num2str(t_run)])


%% Show results
B = B.*sig_X + mu_X;
B = B';
xTrain = xTrain(1:10:end,:)';
figure(2),clf(2)
grid on
dofs = [1,2,3];
hold on
plot3(xTrain(dofs(1),:),xTrain(dofs(2),:),xTrain(dofs(3),:),'x');
scatter3(B(dofs(1),:),B(dofs(2),:),B(dofs(3),:),'or','filled');
view(-30,30)
hold off



%{
%% Scale back up
%Y      =      Y.*sig_Y + mu_Y;
%yhatSp = yhatSp.*sig_Y + mu_Y;
%yhat   =   yhat.*sig_Y + mu_Y;
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
        nlml(find(nlml==0)) = [];
        nlml = reshape(nlml,[length(nlml)/(Q),Q]);
        
        hold on
        plot(t(1:trainSteps:end),hyp_v,'LineWidth',1.5);
        hyp_mean(i,:) = mean(hyp_v(round(length(hyp_v)*fm):end,:));
        plot(t([1,end]),[hyp_mean(i,:); hyp_mean(i,:)],'--k');
        hold off
        xlabel('time (s)');
        legend('$l_{1}$ $(\theta_1)$','$l_2$ $(\dot{\theta_1})$','$l_3$ $(\ddot{\theta_1})$',...
            '$l_{1}$ $(\theta_1)$','$l_2$ $(\dot{\theta_1})$','$l_3$ $(\ddot{\theta_1})$',...
            '$\sigma_s$','Interpreter','Latex');        set(gcf,'Color','w')
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
%{
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
%}