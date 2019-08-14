clc, clear all, close all
fig2pdf = 0;
pdf2ipe = 0;

%% Time settings
ts          = 1/1000;     %[s] Sample time
t_end       = 200;        %[s] Total simulation time
t_still     = 5;          %[s] Standstill time at beginning
t_hypUpdate = [10 55];    %[s] [start stop] hyperparameter optimization
t_learn     = 55;         %[s] Start updating posterior
t_predict   = 65; %[s] Make predictions

t_hypUpdate2 = [70 115];    %[s] [start stop] hyperparameter optimization
t_learn2     = 115;         %[s] Start updating posterior
t_predict2   = 125; %[s] Make predictions

%% Initialize Controller & Plant settings
Tflex_Controller_init

%% Incremental Sparse Spectrum Gaussian Process I-SSGP
D = 80;             % Number of random features
n = 3;              % Input dimension
RAND  = randn(D,n); %
RAND2  = randn(D,n); %
%Hyperparameters (Initial)
ell = ones(1,n).*0.1; % Characteristic length scales
sf  = 1;            % Signal variance

%Hyperparameters (Overwrite)
%ell = [0.31223     0.02772   0.0013815]; % Characteristic length scales
%sf  = 129.5419;              % Signal variance

%Signal noise (Plant input)
sn = (1.670997 + 3.475566)/2; %RMS mA
sn = 2.303584;
sn_init = sn;
sn2 = sn

%% Hyperparameter learning
ts_opti = ts*100;       % [s]  Sample time of hyperparameter optimization
fs_opti = 1/ts_opti;    % [hZ] Sample rate of hyperparameter optimization
bufferSize   = 25;      % Number of stored datapoints
bufferResamp = 50;       % Downsampling ratio before storing date
Z = bufferSize*bufferResamp; 
bufferLength = Z*ts;     % [s] Length of window

%Learning rates: X_new = X_old*(1-beta) + beta*X_opt
beta_init  = 1;             % Initial beta
beta_min   = 0.0000;        % Minimum beta
beta_reduc = 0.991;         % Reduction after each iteration (beta = beta*beta_reduc)

%normalization of data
mu_X  = [0,0,0];
sig_X = [1,1,1];
mu_Y  = 0;
sig_Y = 1;

%Store initial hyperparameters:
SIGMA_init =  RAND.*ell;
SIGMA2_init =  RAND2.*ell;
sf_init    =  sf;
ell_init   =  ell;

%% Run simulation
tic;
sim('TFlex_ISSGP_Twin')
elap_time = toc;

%% Plot Results
Error = error(:)*pi/180;
FF = FF(:);                 % [mA] Feed forward (I-SSGP)
FB = FB(:);                 % [mA] Feed back    (PID)
Ia = Ia(:);                 % [mA] Actual current
Isp = Isp(:);               % [mA] Setpoint current
yTrain = yTraining(:);              % [mA] Training target
xTrain = squeeze(xTraining(:,1,:)); % [deg,deg/s,deg/s^2] Training input
hyperparameter = hyperParam;        % [-] Hyperparameters

% Error, FF & FB
titleString = strcat("Incremental-Sparse Spectrum GP ","(D=",num2str(D),")");
[errorPlot,han] = plotError(ts,Error,FB,FF,'titleStr',titleString,'figNum',151);

% Hyperparameters
[hyperPlot,ha] = plotHyperparams(ts,hyperparameter,'figNum',222);

%% Elapsed time
fprintf('\nDelay introduced by State Variable Filter: %i timesteps\n',SVF.delay)

fprintf('\nElapsed time during simulation: %.3f s (D = %i) \n',[elap_time,D]);
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
rmsErrorStationary = [0.621084,0.293680]*1e-3;
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
    saveas(hyperPlot,fullfile(pwd,'Images','Hyperparameters.pdf'))
    saveas(errorPlot,fullfile(pwd,'Images','Error_ISSGP.pdf'))
end
%% PDF2IPE
if(pdf2ipe)
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end

%% SAVE SOME DATA
save('Results\ISSGP.mat','FF','FB','Error','xTrain','yTrain')
