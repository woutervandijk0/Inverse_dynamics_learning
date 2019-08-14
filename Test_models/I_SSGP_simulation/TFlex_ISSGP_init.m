clc, clear all, close all
fig2pdf = 0;
pdf2ipe = 0;

%% Time settings
ts          = 1/1000;     %[s] Sample time
t_end       = 100;        %[s] Total simulation time
t_still     = 5;          %[s] Standstill time at beginning
t_hypUpdate = [t_end t_end+1];    %[s] [start stop] hyperparameter optimization
t_learn     = 5;         %[s] Start updating posterior
t_predict   = 15; %[s] Make predictions
ts_learn    = ts;

%% Initialize Controller & Plant settings
Tflex_Controller_init

%% Incremental Sparse Spectrum Gaussian Process I-SSGP
D = 80;             % Number of random features
n = 3;              % Input dimension
RAND  = randn(D,n); %

D_opti = 40;
RAND_opti  = randn(D_opti,n); %

%Hyperparameters (Initial)
ell = ones(1,n).*0.1; % Characteristic length scales
sf  = 1;            % Signal variance

%Hyperparameters (Overwrite)
ell = [0.5091   0.0036538   0.0012249]; % Characteristic length scales
sf  = 111.9926;              % Signal variance

%Signal noise (Plant input)
sn = (1.670997 + 3.475566)/2; %RMS mA
sn = 2.303584;
sn_init = sn;

%% Hyperparameter learning
ts_opti = ts*100;       % [s]  Sample time of hyperparameter optimization
fs_opti = 1/ts_opti;    % [hZ] Sample rate of hyperparameter optimization
bufferSize   = 125*2;      % Number of stored datapoints
bufferResamp = 10;       % Downsampling ratio before storing date
Z = bufferSize*bufferResamp; 
bufferLength = Z*ts;     % [s] Length of window

%Learning rates: X_new = X_old*(1-beta) + beta*X_opt
beta_init  = 1;             % Initial beta
beta_min   = 0.0;        % Minimum beta
beta_T     = 0.01
beta_reduc = 0.991;         % Reduction after each iteration (beta = beta*beta_reduc)
beta_reduc = nthroot(beta_T/beta_init,(t_hypUpdate(2)-t_hypUpdate(1))/ts_opti)

%normalization of data
mu_X  = [0,0,0];
sig_X = [1,1,1];
mu_Y  = 0;
sig_Y = 1;

%Store initial hyperparameters:
SIGMA_init =  RAND.*ell;
sf_init    =  sf;
ell_init   =  ell;

%% Run simulation
tic;
sim('TFlex_ISSGP')
elap_time = toc;

%% Plot Results
Error = error(:)*pi/180;
FF = FF(:);                 % [mA] Feed forward (I-SSGP)
FB = FB(:);                 % [mA] Feed back    (PID)
Ia = Ia(:);                 % [mA] Actual current
Isp = Isp(:);               % [mA] Setpoint current
yTrain = yTraining(:);              % [mA] Training target
xTrain = xTraining(:,:); % [deg,deg/s,deg/s^2] Training input
hyperparameter = hyperParam;        % [-] Hyperparameters
noiseIn    = Disturbances.signals(1).values(:);
noiseOut   = Disturbances.signals(2).values(:);
cogging    = Disturbances.signals(3).values(:);
hysteresis = Disturbances.signals(4).values(:);
crossover  = crossover(:);
time       = Disturbances.time(:);

FB = FB(abs(length(FF)-length(FB))+1:end);
crossover = crossover(abs(length(reference)-length(crossover))+1:end);


% Error, FF & FB
titleString = strcat("Incremental-Sparse Spectrum GP ","(D=",num2str(D),")");
[errorPlot,han] = plotError(ts,Error,FB,FF,'titleStr',titleString,'figNum',151);

% Hyperparameters
[hyperPlot,ha] = plotHyperparams(ts,hyperparameter,'figNum',222);

% Disturbances
%[disturbancePlot,han] = plotDisturbances(ts,xTrain(1,:)',noiseIn,noiseOut,hysteresis,cogging,'figNum',444);

% Reference
[refPlot,ha] = plotCrossover(ts,reference,xTrain,Error,crossover,'figNum',101);


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
i_FF      = (50/ts);
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
%save('Results\ISSGP.mat','FF','FB','Error','xTrain','yTrain')


%{
t = [0:length(Error5to35)-1]*1/1000;
figure(251),clf(251)
ha(1) = subplot(2,1,1)
plot(t,Error35to5)

ha(2) = subplot(2,1,2)
plot(t,Error5to35)

linkaxes(ha,'y')
%}