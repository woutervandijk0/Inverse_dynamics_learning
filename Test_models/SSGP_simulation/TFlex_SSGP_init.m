clc, clear all, close all
fig2pdf = 0;
pdf2ipe = 0;

%% Time settings
ts          = 1/1000;     %[s] Sample time
t_end       = 200;        %[s] Total simulation time
t_still     = 10;          %[s] Standstill time at beginning
t_predict   = 20; %[s] Make predictions
t_learn     = 15;
t_hypUpdate = [10 100];    %[s] [start stop] hyperparameter optimization

%% Initialize Controller & Plant settings
Tflex_Controller_init

%% Load dataset:
dataID = 'TFlexSimulation_RN20.mat';
%dataID = 'TFlexADRC_RN20.mat';

[xTrain, yTrain, Ts] = selectData(dataID);

[dof, N] = size(xTrain');
yTrain  = yTrain(:,1)';
xTrain  = xTrain';
%xTrain(3,:)  = movmean(xTrain(3,:),10);
%xSp = xTrain;
%xSp(3,:)  = movmean(xTrain(3,:),10);

%Normalize data
% X
mu_X   = mean(xTrain');
sig_X  = std(xTrain');
xTrain = ((xTrain' - mu_X) ./ sig_X)';
% Y
mu_Y   = mean(yTrain');
sig_Y  = std(yTrain');
yTrain = ((yTrain' - mu_Y) ./ sig_Y)';

%% Noise calculation
i_still = t_still/ts;
signal  = yTrain(1:i_still);
sn_measured = rms(signal);

fprintf('\n')
fprintf('Noise (RMS): %f mA\n',sn_measured)

%% (Hyper)parameters 
%Hyperparameters 
sn   =  0.0160;          % Noise variance
sf   = 0.1;           % Signal variance
l    = [ones(1,dof)]*0.1;   % characteristic lengthscale
%Combine into 1 vector
hyp  = [sf,l];

%overwrite hyperparam
%sn  = 0.1129;
%hyp = [6.8267    5.2009    4.1005    2.9591];

ts_opti = ts*1000;       % [s]  Sample time of hyperparameter optimization
bufferSize   = 25;       % Number of stored datapoints
bufferResamp = 50;       % Downsampling ratio before storing date
Z = bufferSize*bufferResamp; 
bufferLength = Z*ts;     % [s] Length of window

%Learning rates: X_new = X_old*(1-beta) + beta*X_opt
beta_init  = 0.2;             % Initial beta
beta_min   = 0.0000;        % Minimum beta
beta_reduc = 0.9;         % Reduction after each iteration (beta = beta*beta_reduc)

alpha = 1;
sn = sn
%% Data selection (intial)
i_still = t_still/ts;
i_f = [i_still:10:(i_still+10000)];
Mu  = 50;
jU  = floor(length(i_f)/Mu);
i_u = i_f(1:jU:end);
i_s = i_f;

f  = xTrain(:,i_f)';
u  = xTrain(:,i_u)';
s  = xTrain(:,i_s)';

yf = yTrain(:,i_f)';
ys = yTrain(:,i_s)';
yu = yTrain(:,i_u)';

Mf  = length(i_f);
%% Hyperparameter optimization

options         = optimset;
options.Display = 'final';
options.MaxIter = 100;

tic
%{
b = u;
err = yf;
[~, LDinv_c, ~, Dff, LD, ~] = sgpBuildTerms(hyp,sn,f,yf',b,s,alpha);
bound = 0;
% constant term
bound = - 0.5*Mf*log(2*pi);
% quadratic term
bound = bound - 0.5 * sum(err'.^2./Dff');
bound = bound + 0.5 * sum(LDinv_c.^2);

% log det term
bound = bound - 0.5 * sum(log(Dff));
bound = bound - sum(log(diag(LD)));

% trace-like term
bound = bound - 0.5*(1-alpha)/alpha * sum(log(Dff./sn));
bound = -bound
%}
%Optimization exluding signal noise
%
%[hyp_sn nlml] = fminsearch(@(hyp) nlml_I_FITCv2(hyp, sn, u, f, yf, 'FITC'),hyp,options);
[hyp_sn nlml] = fminsearch(@(hyp) sgpNLML(hyp,alpha,f,yf',u,s,yf,Mf),[hyp,sn],options);
hyp = abs(hyp_sn(1:end-1));
sf  = abs(hyp_sn(1:end));
sn  = abs(hyp_sn(end));
toc
%}
%Optimization including signal noise
%{
[hyp_sn nlml] = fminsearch(@(hyp) nlml_I_FITC(hyp, u, f, yf, 'FITC'),[hyp,sn],options);
hyp = abs(hyp_sn(1:end-1));
sn  = abs(hyp_sn(end));
%}

%% Data selection (intial)
%a  = xTrain(i_a)';      % Old inducing points
b  = xTrain(:,i_u)';     % New inducing points
f  = xTrain(:,i_f)';     % Training points
s  = xTrain(:,i_s)';     % Test points

%ya = yTrain(i_b)';
yb = yTrain(1,i_u)';    
yf = yTrain(1,i_f)';
ys = yTrain(1,i_s)';

Ma = length(b);
Mb = length(b);
Mf = length(f);
Ms = length(s);

%% Run FITC over initial window
%Initialize inducing points
b = b(41:end,:);
Ma = length(b);
Mb = length(b)
jitter = 1e-4;

%Build common terms
[LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs, Dff, LD, Kaa_old] = sgpBuildTerms(hyp,sn,f,yf',b,[b;s],alpha);
%Predict
[mu,var,Su] = predictSGP(hyp, [b;s], LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs);

% Split into two parts (a & s)
ma = mu(1:Ma,1);      
Saa = Su(1:Ma,1:Ma);    
mu_s = mu(Ma+1:end,1);    
var_s = var(Ma+1:end,1);  

b_init = b;
a_init = b;
ma_init  = ma;
Saa_init = Saa;

figure(112),clf(112);
hold on
plot(i_u,yb,'x')
plot(i_f,yf)
plot(i_s,ys)
plot(i_s,mu_s,'LineWidth',2)
hold off

%% Run simulation
tic;
sim('TFlex_SSGP')
elap_time = toc;

%% Plot Results
Error = error(:)*pi/180;
FF = FF(:);                 % [mA] Feed forward (I-SSGP)
FB = FB(:);                 % [mA] Feed back    (PID)
Ia = Ia(:);                 % [mA] Actual current
Isp = Isp(:);               % [mA] Setpoint current
yTrain = yTraining(:);              % [mA] Training target
xTrain = squeeze(xTraining(1,:,:))'; % [deg,deg/s,deg/s^2] Training input
%hyperparameter = hyperParam;        % [-] Hyperparameters

iDel = length(FF)-length(FB);
FF(1:iDel) = [];
% Error, FF & FB
titleString = strcat("Streaming Sparse GP ","($N_u=",num2str(Mb),"$)");
[errorPlot,han] = plotError(ts,Error,FB,FF,'titleStr',titleString,'figNum',151);

% Hyperparameters
%[hyperPlot,ha] = plotHyperparams(ts,hyperparameter,'figNum',222);

%% Save training data to dataset
X = xTrain;
Y = yTrain;
save('C:\Users\wout7\OneDrive - student.utwente.nl\ME - Master\Thesis\Data\InverseDynamics\TFlexSimulation_RN20.mat','X','Y')

%% Elapsed time
fprintf('\nDelay introduced by State Variable Filter: %i timesteps\n',SVF.delay)

fprintf('\nElapsed time during simulation: %.3f s \n',[elap_time]);
fprintf("Time, using 'solve_chol_sfun' during simulation: %.3f s \n",t_end-t_learn);

%% Noise calculation
i_still = t_still/ts;
signal  = yTrain(1:i_still);
sn_measured = rms(signal);

fprintf('\n')
fprintf('Noise (RMS): %f mA\n',sn_measured)

%% ERROR 
Error = error(:);
N = length(yTrain(:));
i_still = t_still/ts;
i_noFF    = t_predict/ts;
i_FF      = (t_predict+10)/ts;
if N > i_FF
    format shortEng
    fprintf('\n')
    fprintf('RMS error (10^-3 degree):\n')
    fprintf('Before I-SSGP: %f \n',rms(Error(i_still:i_noFF))*10^3)
    fprintf('After  I-SSGP: %f \n',rms(Error(i_FF:end))*10^3)
    fprintf('Stationary   : %f  (at 0 degree)\n',rms(Error(1:i_still))*10^3)
    format
else
    fprintf('\nNo predictions made using I-SSGP... \n')
end

%% Save Figures
if(fig2pdf)
    saveas(errorPlot,fullfile(pwd,'Images','Error_IFITC.pdf'))
end
%% PDF2IPE
if(pdf2ipe)
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end

%% SAVE SOME DATA
%save('Results\SSGP.mat','FF','FB','Error')