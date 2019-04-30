clc, clear all, close all

%% TFlex plant
s = tf('s');
P= 1/(0.2*s^2 + 0.001*s+11.36); % model of the plant
%P = 1/s^2;
[Pnum,Pden] = tfdata(P,'v');

%% Reference generator
seed = randi(50000,1);       %
sp_ts = 2;      %[s] Period
tm = 0.5;       %[s] Settle time

%% state variable filter
omega_n = 50*2*pi;
a0 = omega_n^3;
a1 = 3*omega_n^2;
a2 = 3*omega_n;

%% PID
ts = 1/1000;
I_limit = inf; %2000; %[mA]

m_eq = 0.2;
crossOver = 10*2*pi;
alpha = 0.1;
beta  = 5;
PID.kp    = m_eq*crossOver^2/sqrt(1/alpha)
PID.tau_z = sqrt(1/alpha)/crossOver;
PID.tau_i = beta*PID.tau_z;
PID.tau_p = 1/(crossOver*sqrt(1/alpha))

%% SSGP
D = 50;
n = 3;
RAND  = randn(D,n);
ell = ones(1,n).*0.01;
sf  = 0.01;
sn  = 1.55;
Z = 2000;
bufferSize = Z/100;
ts_opti = ts*100;

%Learning rates:
beta_init  = 1;
beta_min   = 0.001;
beta_reduc = 0.99;

%Time settings
t_end       = 200;        %[s] Total simulation time
t_hypUpdate = [5 t_end]; %[s] [start stop] hyperparameter optimization
t_learn     = t_hypUpdate(1)+30;         %[s] Start updating posterior
t_predict   = t_learn+10; %[s] Make predictions
t_iMean     = 30;

%normalization of data
mu_X  = [0,0,0];
sig_X = [0.2,2,10];
mu_Y  = 0;
sig_Y = 5;
sn = 0.0581;
%sn = sn*2;
%
%m_eq = 2*m_eq;
%% Run simulation
tic
sim('TFlex_ISSGP')
toc

%% Show results
figure(1),clf(1)
t = noiseSignal.time;
noise = noiseSignal.signals.values(:);
noise = noise./sig_Y;

subplot(1,2,1)
plot(t,noise)
subplot(1,2,2)
plot(t,detrend(noise,5))

N = length(noise);
sigma = sqrt(sum((noise-0).^2)/N)
sqrt(sigma)