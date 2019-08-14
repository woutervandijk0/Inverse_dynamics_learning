clc, clear all,% close all
fig2pdf = 0;
pdf2ipe = 0;

%% Time settings
ts          = 1/1000;     %[s] Sample time
t_end       = 200;        %[s] Total simulation time
t_still     = 10;         %[s] Standstill time at beginning
t_predict   = 65;         %[s] Make predictions
t_learn     = 55;         %[s]

%% Initialize Controller & Plant settings
Tflex_Controller_init

%% Load dataset:
dataID = 'TFlexSimulation_RN20.mat';
%dataID = 'TFlexADRC_RN20.mat';

[xTrain, yTrain, Ts] = selectData(dataID,'fig',false);

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
%xTrain = ((xTrain' - mu_X) ./ sig_X)';
% Y
mu_Y   = mean(yTrain');
sig_Y  = std(yTrain');
%yTrain = ((yTrain' - mu_Y) ./ sig_Y)';

%% (Hyper)parameters 
%Hyperparameters 
sn   = 2.860155;          % Noise variance
sf   = 0.5;           % Signal variance
l    = [ones(1,dof)];   % characteristic lengthscale

%overwrite hyperparam
sf = 142.3843
l = 1./[0.33922    0.026313   0.0014776];
%Combine into 1 vector
hyp  = [sf,l];
%% Data selection (intial)
i_still = t_still/ts;
i_f = [i_still:5:i_still+5000];
Mu  = 50;
jU  = floor(length(i_f)/Mu);
i_u = i_f(1:jU:end);
i_s = i_f;

f  = xTrain(:,i_f)';
u  = xTrain(:,i_u)';
s  = xTrain(:,i_s)';

yf = yTrain(:,i_f)';
ys = yTrain(:,i_s)';

Mf  = length(i_f);
%% Hyperparameter optimization
options = optimset;
options.Display = 'final';
options.MaxIter = 50;
%Optimization exluding signal noise
%{
[hyp_sn nlml] = fminsearch(@(hyp) nlml_I_FITCv2(hyp, sn, u, f, yf, 'FITC'),hyp,options);
hyp = abs(hyp_sn);
%}

%Optimization including signal noise
%{
[hyp_sn nlml] = fminsearch(@(hyp) nlml_I_FITC(hyp, u, f, yf, 'FITC'),[hyp,sn],options);
hyp = abs(hyp_sn(1:end-1));
sn  = abs(hyp_sn(end));
%}

%% Run FITC over initial window
[mu_s, var_s, mu_u, var_u, Kuu] = FITC(hyp,sn,u,f,yf,s);

figure(999),clf(999)
hold on
plot(mu_s)
plot(yf)
hold off

%% Remove inducing points
%Keep Nkeep inducing points
Nkeep = 20;
Nremove = size(u,1)-Nkeep;
[u,Kuu,Lu,mu_u,var_u,Mu] = updateInducing(hyp,sn,u,mu_u,var_u,Kuu,u(Nremove,:),Nremove);
u_init = u;

%% Run simulation
tic;
sim('TFlex_IFITCv2')
elap_time = toc;

%% Plot Results
Error = error(:)*pi/180;
FF = FF(:);                 % [mA] Feed forward (I-SSGP)
FB = FB(:);                 % [mA] Feed back    (PID)
Ia = Ia(:);                 % [mA] Actual current
Isp = Isp(:);               % [mA] Setpoint current
yTrain = yTraining(:);              % [mA] Training target
xTrain = squeeze(xTraining(1,:,:))'; % [deg,deg/s,deg/s^2] Training input
hyperparameter = hyperParam;        % [-] Hyperparameters

iDel = length(FF)-length(FB);
FF(1:iDel) = [];
% Error, FF & FB
titleString = strcat("Incremental-FITC ","($N_u=",num2str(Mu),"$)");
[errorPlot,han] = plotError(ts,Error,FB,FF,'titleStr',titleString,'figNum',151);

% Hyperparameters
%[hyperPlot,ha] = plotHyperparams(ts,hyperparameter,'figNum',222);

%% Save training data to dataset
X = xTrain;
Y = yTrain;
%save('C:\Users\wout7\OneDrive - student.utwente.nl\ME - Master\Thesis\Data\InverseDynamics\TFlexSimulation_RN20.mat','X','Y')

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
save('Results\IFITC.mat','FF','FB','Error')