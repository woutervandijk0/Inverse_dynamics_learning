clear all,% close all
%% Run once:
initialize();

%% Select and open Dataset ('Default' opens file explorer)
dataID = 'TFlex1D-2.mat';
%dataID = 'TFlex1D5G.mat';
dataID = 'TFlexADRC_RN20.mat'
%dataID = 'DoublePendulum.mat'

%% Settings 
param_update   =  true;  % Update hyperparameters in the loop (true/false)
param_fix      =  [];    % Exclude hyperparams from update (by indices) (only if param_updata == true)
showAnimation  =  false;  % Show an (online) animation of predictions
loadSetpoint   =  false;  %
compareWTrue   =  false; % Compare with real data (only for periodic datasets)
loadParams     =  false; % Load hyper parameters from previous run
saveParams     =  true;  % Save hyper parameters
useRecurrent   =  false; % Use a feedbackloop of the predicted torques back in to the GP
recordVid      =  false;

%% GP settings
Z = 50;        % Size of drifting window
M = 25;         % Number of inducing points (for sparse GPR)

batchSize  =  1;           % Size of batched received each timestep
resamp     =  1;           % Resample factor (1 = no resampling)
N_query    =  max(resamp,batchSize);    % Predict N number of timesteps in the future
maxSamples =  5e3;         % Max number of samples

method     =  [2,4];       % Sampling method (see initSampling.m & updateSampling.m)
N_search   =  10;          % Max. iter. of gradient descent for inference

% Learning rates (exponential smootheners)
alpha = 1;         % Hyperparameters
beta  = 0.1;       % Inducing points
kappa = 1;         % Prediction
zeta  = 1;         % N_search

% Approximation method:
s = 1;      %S = 0: VFE    0<s<1: SPEP     s = 1: FITC

%% Load dataset & Normalize 
[X,Y,ts,N_io] = selectData('dataset',dataID,'fig',true,'figNum',1);
N = N_io(1);    % Number of inputs
Q = N;          % Number of latent functions
P = N_io(2);    % Number of outputs
TS =  batchSize*ts;     % Stepsize over each batch update

mu_X  = mean(X);
sig_X = std(X);
X = (X - mu_X) ./ sig_X;

if loadSetpoint == true
    Xsp = loadSp(dataID);
    Xsp = (Xsp - mu_X) ./ sig_X;
    Xsp = [X(:,1), X(:,2), Xsp(:,3)];
else
    Xsp = X;
end

%select active signals
NX = size(X,2);     % Dimension of input vector
if useRecurrent == true
    Xsp(:,NX+1) = zeros(1,length(Xsp));
    NX = NX+1;
end


X = X(30000:end,:);
Xsp = Xsp(30000:end,:);
Y = Y(30000:end,:);
%% Gaussian Process Structure
% Covariance function
cov     =   @covSEard;              % Squared exponentioal covariance with automatic relevance determination
cov_sp  =   {'apxSparse',{cov}};    % Sparse version of cov
% Mean function
mean_gp =   @meanZero;              % Zero mean function
% Likelihood
lik     =   {@likGauss};            % Gaussian likelihood
% inference
inf     =   @infGaussLik;           % Inference gaussian likelihood
inf     =   @(varargin) inf(varargin{:},struct('s',s)); % Sparse version of inf

%% Hyperparameters (default unit)
% Likelihood
sn      =   ones(1,Q);       % Std of likelihood function
% Covariance
sf      =   ones(1,Q);        % Std covariance (at t=0, 1)
ell     =   ones(NX,Q);       % Length scales (at t=0, 1)

% Load previous hyperparameters
if loadParams == true
    [sn, sf, ell] = loadHyperparams(dataID,useRecurrent);
    sn = sn'; sf = sf'; ell = ell'
    %ell = ell-1;
end

% Prior distributions - Exlude some hyperparams from optimization
if param_update == true && length(param_fix) > 0
    [inf] = fixHyperparams(ell,inf,param_fix);
end

% Combine all hypParams to 1 stucture
for ii = 1:Q
    [xu,indc(ii,:)]  = initSampling(method(1),Z,M,X);   % Inducing points
    HYP(ii).hyp.xu  = xu;
    HYP(ii).hyp.lik = sn(ii);
    HYP(ii).hyp.cov = [ell(:,ii);sf(:,ii)];
end

%Create a 'GP' structure containing all the GP settings.
write2struct

%% Preallocate some matrices
tic
%Loop over the following indices of X
i_loop  = (resamp*Z + batchSize):batchSize:(min(maxSamples,length(X))-(N_query+1));
N_loop  = length(i_loop) + 1;  % + 1 because of initial step.

% In order to track predictions & hyperparams pre-allocate matrices;
hypOpt  = zeros(P,NX+1,N_loop);     % For tracking hyperparameter development
muPred  = zeros(P,N_loop*N_query);    % For mean predictions
varPred = zeros(P,N_loop*N_query);            % For variance prediction
T       = zeros(1,N_loop);            % For t
I       = ones(1,N_loop);             % For indices
Iall    = ones(P,N_loop*N_query);     % For indices (t+N_query predictions)
%F       = zeros(1,N_loop-1);

%% Drifting sparse GPR - intitial timestep (iter = 1)
%Indices vectors
indi_train   =   [1 :resamp:(Z*resamp)];
indi_predict =   indi_train(end) + [1:N_query];
indi_tot     =   union(indi_train,indi_predict);  % indices of both

%time vector and plot limits
t_train      =         indi_train*ts;   % For training points
t_pred       =       indi_predict*ts;   % For predictions
t_tot        =           indi_tot*ts;   % For training + predictions
Xlimits      =  [indi_tot(1)-5, indi_tot(end)+5]*ts;   % Plot limits

% First time step
iter = 1;

% Select initial training and query data
X_train     =   X(indi_train,:);
Y_train     =   Y(indi_train,:);
X_predict   =   Xsp(indi_predict,:);
X_tot       =   X(indi_tot,:);
T(iter)     =   t_pred(1);
I(iter)     =   indi_predict(1);
Iall(iter:(iter*N_query)) = indi_predict;

% Hyperparameter optimization
if param_update == true
    for ii = 1:Q
        hyp_old           =  HYP(ii).hyp.cov;
        HYP(ii).hyp       =  minimize(HYP(ii).hyp,@gp,-N_search,inf,mean_gp,cov_sp,lik,X_train,Y_train(:,ii));
        HYP(ii).hyp.cov   =  (1-alpha)*hyp_old + alpha*HYP(ii).hyp.cov; % Quadratic smoothener
        hypOpt(ii,:,iter) =  HYP(ii).hyp.cov;  % Save data
    end
end

% Conditioning on training data & prediction
for ii = 1:P
    [nlZ dnlZ, post(ii)]             = gp(HYP(ii).hyp,inf,mean_gp,cov_sp,lik,X_train,Y_train(:,ii));
    [ymuv(:,ii),ys2s(:,ii),~,~,~,~]  = gp(HYP(ii).hyp,inf,mean_gp,cov_sp,lik,X_train,post(ii),X_predict);
end
muPred(:,iter:(iter*N_query)) = ymuv';
varPred(:,iter:(iter*N_query))= ys2s';
if useRecurrent == true
    Xsp(iter:(iter*N_query),NX) = (ymuv - mu_Y) ./ sig_Y;
end

%Start figure
if showAnimation == true;
    h = figure(112);clf(h);
end
% start loop
iter = 2;
t_iter = 0;
disp('Simulating: ');
for i = i_loop
    %% Update moving window
    % Indices vectors:
    indi_train    =  indi_train   + batchSize;
    indi_predict  =  indi_predict + batchSize;
    indi_tot      =  indi_tot     + batchSize;
    % Time vectors:
    t_train       =  t_train   + TS;
    t_pred     =  t_pred + TS;
    t_tot         =  t_tot     + TS;
    Xlimits       =  Xlimits   + TS;
    % Training and query data:
    X_train   = X(indi_train,:);
    Y_train   = Y(indi_train,:);
    X_predict = Xsp(indi_predict,:);
    X_tot     = X(indi_tot,:);
    I(iter)   = indi_predict(1);
    T(iter)   = t_pred(1);
    Iall(((iter-1)*N_query+1):(iter*N_query)) = indi_predict;
    tic;
    % Inducing points
    xu_old    =    HYP(1).hyp.xu;      % Old inducing points
    xu_new    =    updateInducingPoints(xu_old,X_train,indc,beta,batchSize,Z,method(2));
    
    for ii = 1:Q
        HYP(ii).hyp.xu = xu_new;       % Update inducing points
    end
    
    %% Hyperparameter optimization & pseudo input search
    if param_update == true
        for ii = 1:Q
            hyp_old(:,ii)       =  HYP(ii).hyp.cov;  % initial hyperparams
            HYP(ii).hyp         =  minimize(HYP(ii).hyp,@gp,-N_search,inf,mean_gp,cov_sp,lik,X_train,Y_train(:,ii));
            HYP(ii).hyp.cov     =  (1-alpha)*hyp_old(:,ii) + alpha*HYP(ii).hyp.cov; % Quadratic smoothener
            hypOpt(ii,:,iter)   =  HYP(ii).hyp.cov;  % Save hyperparam data
        end
        N_search = max(N_search*zeta,2);
    end
    
    %% Prediction
    for ii = 1:Q
        [ymuv(:,ii),ys2s(:,ii)]  = gp(HYP(ii).hyp,inf,mean_gp,cov_sp,lik,X_train,Y_train(:,ii),X_predict);
        if showAnimation == true
            [ymuv_tot,ys2s_tot]  = gp(HYP(ii).hyp,inf,mean_gp,cov_sp,lik,X_train,Y_train(:,ii),X_tot);
        end
    end
    t_iter = t_iter+toc;
    i_add = ((iter-1)*N_query+1):(iter*N_query);
    muPred(:,i_add) = (1-kappa)*muPred(:,i_add(1)-1) + kappa*ymuv';      %save data of t+N_query step
    %varPred(:,i_add) = (1-kappa)*varPred(:,i_add(1)-1) + kappa*ys2s';  %save smoothened data of t+1 step
    varPred(:,i_add) = ys2s';  %save smoothened data of t+1 step
    if useRecurrent == true
        Xsp(i_add,NX) = (ymuv - mu_Y) ./ sig_Y;
    end
    
    %% Plot (moving) time window and predictions
    if showAnimation == true
        plot(t_tot,Y(indi_tot,:));          %actual values
        hold on
        for ii = 1:Q
            plot(t_tot,ymuv_tot,'-k','LineWidth',1.5)
            plot(t_pred,ymuv,'.--k');              % Predicted mean
            plot(t_pred,ymuv+2*sqrt(ys2s),'-xk'); % 95% confidence bound
            plot(t_pred,ymuv-2*sqrt(ys2s),'-xk'); % 95% confidence bound
        end
        hold off
        xlim(Xlimits); title(['TARGET: Torque/Current']);
        %ylim([200 800]);
        if recordVid == true
            F(iter-1) = getframe(gcf) ;
        end
        drawnow;
    end
    %% Update Iterations
    iter  =  iter + 1;
    if mod(iter,round(N_loop/10)) == 0
        disp([num2str(round(iter/N_loop*100)),' %'])
    end
end

%% Rescale data (if necessary)
%Y = Y*Y_max + Y_avg;
%YMUVall = YMUVall.*Y_max + Y_avg;

%% Save Video
if recordVid == true && showAnimation == true
    % create the video writer with 1 fps
    writerObj = VideoWriter('myVideo.avi');
    writerObj.FrameRate = 150;
    % set the seconds per image
    % open the video writer
    open(writerObj);
    % write the frames to the video
    for i=1:length(F)
        % convert the image to a frame
        frame = F(i) ;
        writeVideo(writerObj, frame);
    end
    % close the writer object
    close(writerObj);
end
%% Plot Results
%Some time vectors
tall      = [1:size(X,1)]*ts;
tlong     = T(1)+([0:N_loop*N_query-1])*ts;
t_hyp     = T(1:iter-1);
i_predict = [(resamp*Z):1:length(X)];

%Hyperparams
if param_update == true
    figure(555),clf(555)
    hold on
    fm = 4/5;
    for ii = 1:Q
        subplot(1,Q,ii);
        sn_vec(ii) = HYP(ii).hyp.lik;
        hyp = squeeze(hypOpt(ii,:,1:iter-1))';
        plot(t_hyp',hyp,'LineWidth',1.5);
        hold on
        hyp_mean(:,ii) = mean(hyp(round(length(hyp)*fm):end,:))';
        plot(t_hyp([1,end]),[hyp_mean(:,ii),hyp_mean(:,ii)]','--k');
        hold off
        xlabel('[s]');
        legend('$l_1$ $(\theta)$','$l_2$ $(\dot{\theta})$','$l_3$ $(\ddot{\theta})$','$\sigma_s$','Interpreter','Latex');
    end
    hold off
    
    %Store hyperparams in .mat file
    if saveParams == true
        sn  = sn_vec';
        ell = hyp_mean(1:end-1,:)';
        sf  = hyp_mean(end,:)';
        folderName = 'Results\hyperparamSettings\';
        if useRecurrent == true
            paramID = [dataID(1:end-4),'_recurrent_param.mat'];
        else
            paramID = [dataID(1:end-4),'_param.mat'];
        end
        save([folderName,paramID],'sn','ell','sf')
    end
    
end

%Load underlying data (for periodic datasets);
if compareWTrue == true
    load([dataID(1:end-4),'real.mat']);
    Y_new   = Y_mean;
    sigma_s = noise_est;
end

% Plot N-step ahead predictions & actual values
figure;
for ii = 1:P
    subplot(1,P,ii)
    hold on
    h1 = scatter(tall,Y(:,ii)','MarkerEdgeColor','none','MarkerFaceColor','b','MarkerFaceAlpha',.05);
    if compareWTrue == true
        h2 = plot(tall,Y_new(:,:)','r','LineWidth',2.5);
        h3 = plot(tall,Y_new' + sigma_s','r');
        h3 = plot(tall,Y_new' - sigma_s','r');
    end
    h4  = plot(tlong,muPred(ii,:),'.-k','LineWidth',2);
    h5  = plot(tlong,muPred(ii,:)+sqrt(varPred(ii,:)),'k');
    h5  = plot(tlong,muPred(ii,:)-sqrt(varPred(ii,:)),'k');
    
    %Legend
    if compareWTrue == true
        legend([h1,h2,h3,h4,h5],'$f_{measure}$','$f_{true}$','$\sigma_{true}$','$$f_{pred}$','$\sigma_{pred}$','Interpreter','Latex','FontSize',12)
    else
        legend([h1,h4,h5],'$f_{measure}$','$f_{pred}$','$\sigma_{pred}$','Interpreter','Latex','FontSize',12);
    end
    hold off
end
xlabel('t (s)')
ylabel('I (mA)')

%% Error measure
disp(' ');
disp(['t+',num2str(N_query),' predictions:']);
i_start = 100;
if compareWTrue == true
    Y_m = Y_new(Iall,:)';
else
    Y_m = Y(Iall,:)';
end
Y_m = Y_m(:,i_start:end);
Y_p = muPred(:,i_start:end); 
NMSE = errorMeasure(Y_m,Y_p,'method','NMSE','show',true);
MAE = errorMeasure(Y_m,Y_p,'method','MAE','show',true);
MSE = errorMeasure(Y_m,Y_p,'method','MSE','show',true);
RMSE = errorMeasure(Y_m,Y_p,'method','RMSE','show',true);

disp(' ');
disp('Comp. time [s]')
disp(['total:     ',num2str(t_iter)])
disp(['Per iter.: ',num2str(t_iter/iter)])

%% FRF
figure;
frfData = X(:,3);
%frfData = Y;
fs = 1/ts;
n = length(frfData);
muFrf = fft(frfData);
f = (0:n-1)*(fs/n);
power = abs(muFrf).^2/n;
plot(f,power)
xlabel('Frequency')
ylabel('Power')
xlim([0 50])