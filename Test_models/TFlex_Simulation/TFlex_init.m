clc, clear all, close all
ts = 1/1000;
fig2pdf = 0;
pdf2ipe = 0;
%% Time settings
t_end       = 200;        %[s] Total simulation time
t_hypUpdate = [5 100]; %[s] [start stop] hyperparameter optimization
t_learn     = t_hypUpdate(1)+50;         %[s] Start updating posterior
t_predict   = t_learn+10; %[s] Make predictions

%Settings for no hyperparam learning
% t_end       = 150;        %[s] Total simulation time
% t_hypUpdate = [t_end+1 t_end+1]; %[s] [start stop] hyperparameter optimization
% t_learn     = 0.01;         %[s] Start updating posterior
% t_predict   = t_learn+30; %[s] Make predictions

%% TFlex plant
s = tf('s');
P = 1/(0.2*s^2 + 0.74*s + 11.46)       %Tflex
P2 = 1/((0.2*s^2 + 0.74*s + 11.46)*(0.000001*s^2 + 0.00001*s + 0.5e3^2*0.00001)); %[mA/deg] Transfer function of Tflex
[Pnum,Pden] = tfdata(P,'v');

%% Reference generator
% Skewsine Reference Generator
seed  = 0; %randi(20000,1); %
sp_ts = 2;      % [s] Period
tm    = 1.0;    % [s] Settle time
sp_ts = 2
tm    = 0.9;

%Transient reference generator
r = 1e2;
h = 10*ts;

%% state variable filter (2nd Order)
omega_n = 50*2*pi;  %[rad/s] Natural frequency
% Coefficients
a0 = omega_n^3;
a1 = 3*omega_n^2;
a2 = 3*omega_n;

%Transfer function
SVF   = 1/(s^3 + a2*s^2 + a1*s + a0);   % Continuous
SVF_d = c2d(SVF,ts);                    % Discrete

%Delay (at controller crossover)
crossover = 35;
[mag,phase,wout] = bode(SVF,crossover);
svf_delay = -(phase)/(2*pi*wout);
svf_delay = round(svf_delay/(ts*10));
fprintf('\nDelay introduced by State Variable Filter (at crossover): %i timesteps\n',svf_delay)

%% PID
I_limit = 2000; % [mA]   Current limit
gainMotor = 5.56;  % [Nm/A] Motor constant

crossOver = 35*2*pi;     %[rad/s]
m_eq  = 0.2;     % Equivalent mass
alpha = 0.1;     % Phase lead
beta  = 2;       % Integral action

%Serial form
kp    = m_eq*crossOver^2/sqrt(1/alpha);
tau_z = sqrt(1/alpha)/crossOver;
tau_i = beta*tau_z;
tau_p = 1/(crossOver*sqrt(1/alpha));

%Parallel form
Kp = kp*(1+(tau_z-tau_p)/tau_i);
Ki = kp/tau_i;
Kd = kp*(tau_z-tau_p*(1+(tau_z+tau_p)/tau_i));

% Lowpass (for derivative action)
LP = 1/(tau_p*s+1);         % Continuous
LP_d = c2d(LP,ts);          % Discrete
[LPnum,LPden] = tfdata(LP_d,'v');

%Transfer function (PID)
Cpid = kp * (tau_z*s +1)*(tau_i*s + 1)/(tau_i*s*(tau_p*s+1));   % Continuous
Cpid_d = c2d(Cpid,ts,'tustin');                                 % Discrete

%Transfer function (Plant, discrete)
P_d  = c2d(P,ts);
P2_d = c2d(P2,ts);

% Open loop stability
Loopd  = loopsens(P_d,Cpid_d);
figure(80063)
set(gcf,'Color','White')
%Bodeplot
subplot(1,3,1)
bodeplot(Cpid_d,P_d)
hold on
margin(Cpid_d*P_d)
legend('C','P','CP')
hold off

%Nyquist diagram
subplot(1,3,2)
nyquist(Cpid_d*P_d)
legend('CP_d')
xlim([-10 0])
axis equal

%Pole zero map
subplot(1,3,3)
pzmap(Cpid_d*P_d)
legend('CP_d')
xlim([-1.1 1.1])
axis equal

close all
%% Smith Predictor && Feed Forward
m_est = 0.2;
d_est = 0;
k_est = 0;
%Estimated plant
P_est   = 1/(m_est*s^2);         % Continuous
P_est_d = c2d(P_est,ts);        % Discrete
[P_estnum,P_estden] = tfdata(P_est_d,'v');

%% Incremental Sparse Spectrum Gaussian Process I-SSGP
D = 100;             % Number of random features
n = 3;              % Input dimension
RAND  = randn(D,n); %
%Hyperparameters (Initial)
ell = ones(1,n).*0.1; % Characteristic length scales
sf  = 140;            % Signal variance

%Hyperparameters (Overwrite)
ell = [0.31223     0.02772   0.0013815]; % Characteristic length scales
sf  = 129.5419;              % Signal variance

%Signal noise (Plant input)
sn = (1.670997 + 3.475566)/2; %RMS mA
%sn = sqrt(1.670997);

%% Discrete Filter
tau = -0.1;
a_filt = 1-exp(2*pi*ts/tau)
a_filt1 = 0.01;
a_filt2 = a_filt1;
%lowpass
LP = 1/(10*s+1);         % Continuous
LPn_d = c2d(LP,ts);          % Discrete
[LPnnum,LPnden] = tfdata(LP_d,'v');
%%
% Hyperparameter learning
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
sf_init    =  sf;
ell_init   =  ell;

%% Cogging 
angle = linspace(-23,23,500);
f = [10, 5, 20, 2.5, 1.25];  % Frequencies
p = [0, 0, -5, 0, 2];        % Phase delay
a = [40, -20, 30, 2, 0.1];   % Amplitude (relative)
cT    = sum( a'.*sin(((angle+p')*2*pi)./f'));
[maxValue,index] = max(cT);
cT    = a'.*sin(((angle(index)+p')*2*pi)./f');
a = a./maxValue;              % Normalized amplitudes 

%% Run simulation
m_eq = 0;
tic;
sim('TFlex_ISSGP')
elap_time = toc;

%% Plot Results
Error = error(:);
FF_SSGP = FF_SSGP(:);
FF_RBD = FF_RBD(:);
controlOutput = controlOutput(:);
torqueError   = trainingTarget(:);
actualCurrent = actualCurrent(:);
setpointCurrent = setpointCurrent(:);
t     = [0:length(Error)-1]*ts;
ist  = 1000;
tOn1 = t_learn;
tOn2 = t_end;
t1 = [tOn1 tOn1];
t2 = [tOn2 tOn2];

fig151 = figure(151),clf(151)
ylimits = [-0.00005 0.00005];
han(1,1) = subplot(3,1,1);
hold on
plot(t(ist:end),Error(ist:end))
ylimit(1) = min([Error(ist:end);ylimits(1)]);
ylimit(2) = max([Error(ist:end);ylimits(2)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
title(['I-SSGP ','(D=',num2str(D),')'])
%legend('\theta_1')
%ylim(ylimits)
ylabel('Error (deg)')
hold off

han(2,1) = subplot(3,1,2);
hold on 
plot(t(ist:end),controlOutput(ist:end))
ylimit(1) = min([controlOutput(ist:end)]);
ylimit(2) = max([controlOutput(ist:end)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
%legend('u')
ylabel('FB (mA)')
hold off

han(3,1) = subplot(3,1,3);
hold on 
plot(t(ist:end),FF_SSGP(ist:end))
ylimit(1) = min([FF_SSGP(ist:end)]);
ylimit(2) = max([FF_SSGP(ist:end)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
%legend('FF')
ylabel('I-SSGP FF (mA)')
xlabel('time (s)')
hold off

[fig151,han] = subplots(fig151,han)

%% Setpoint
q = squeeze(trainingInput(:,1,:));
%q = trainingInput';
%
fig150 = figure(150); clf(150);
ha(1,1) = subplot(4,1,1);
hold on
plot(t,q(1,:))
ylabel('(rad)')
hold off

ha(2,1) = subplot(4,1,2);
hold on
plot(t,q(2,:))
ylabel('(rad/s)')
hold off

ha(3,1) = subplot(4,1,3);
hold on
plot(t,q(3,:))
ylabel('(rad/s^2)')
hold off

ha(4,1) = subplot(4,1,4);
hold on
plot(t,FF_SSGP,'r')
ylabel('(N m)')
hold off

[fig150,ha] = subplots(fig150,ha)

%% Hyperparameters
hyperparameter = hyperParam;
fig222 = figure(222),clf(222);
tHyp = [0:length(hyperparameter)-1].*ts; %ts_opti;
han222(1,1) = subplot(2,1,1);
plot(tHyp,hyperparameter(:,1:3)','LineWidth',1.5)
legend('$l_1 \sim \theta$','$l_2 \sim \dot{\theta}$','$l_3 \sim \ddot{\theta}$','Interpreter','Latex')
title('Hyperparameters')
han222(2,1) = subplot(2,1,2);
plot(tHyp,hyperparameter(:,4)','LineWidth',1.5)
legend('$\sigma_f$','Interpreter','Latex')
xlabel('t (s)')

[fig222,han222] = subplots(fig222,han222,'gabSize',[0.09, 0.03])

ell = hyperparameter(end-1,1:3);
sf = hyperparameter(end-1,4);
disp('Final Hyperparameters:')
disp(['sf:  ',num2str(sf)])
disp(['ell: ',num2str(ell)])
format

%% Elapsed time
fprintf('\nDelay introduced by State Variable Filter: %i timesteps\n',svf_delay)

fprintf('\nElapsed time during simulation: %.3f s (D = %i) \n',[elap_time,D]);
fprintf("Time, using 'solve_chol_sfun' during simulation: %.3f s \n",t_end-t_learn);

%% Noise calculation
signal = torqueError(5/ts:end);
mu = mean(signal);

sn_measured = rms(signal-mu);
fprintf('\n')
fprintf('Noise (RMS): %f mA\n',sn_measured)

%% ERROR 
N = length(trainingTarget(:));
i_noISSGP = t_predict/ts;
i_ISSGP   = (100)/ts;
rmsErrorStationary = [0.621084,0.293680]*1e-3;
if N > i_ISSGP
    format shortEng
    fprintf('\n')
    fprintf('RMS error (10^-3 degree):\n')
    fprintf('Before I-SSGP: %f \n',rms(Error(1:i_noISSGP))*10^3)
    fprintf('After  I-SSGP: %f \n',rms(Error(i_ISSGP:end))*10^3)
    fprintf('Stationary   : %f  (at 3.3 degree)\n',rmsErrorStationary(1)*10^3)
    fprintf('Stationary   : %f  (at -3.3 degree)\n',rmsErrorStationary(2)*10^3)
    format
else
    fprintf('\nNo predictions made using I-SSGP... \n')
end

%% Save Figures
if(fig2pdf)
    saveas(fig222,fullfile(pwd,'Images','Hyperparameters.pdf'))
    saveas(fig150,fullfile(pwd,'Images','TrainingData.pdf'))
    saveas(fig151,fullfile(pwd,'Images','Error_FB_FF.pdf'))
end
%% PDF2IPE
if(pdf2ipe)
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end
