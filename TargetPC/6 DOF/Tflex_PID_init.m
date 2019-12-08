clc, clear all, close all
ts   = 1/1000;

%% PID
I_limit_max = 500; % [mA]   Current limit (Max.)
I_limit_min = -500;% [mA]   Current limit (Min.)
gainMotor   = 5.56;  % [Nm/A] Motor constant

crossOver = 15;     %[Hz]
crossOver = crossOver*2*pi;
m_eq  = 0.2;     % Equivalent mass
alpha = 0.1;%0.119;   % Phase lead
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
s    = tf('s');
LP   = 1/(tau_p*s+1);         % Continuous
LP_d = c2d(LP,ts);          % Discrete
[LPnum,LPden] = tfdata(LP_d,'v');

%Transfer function (PID)
Cpid = kp * (tau_z*s +1)*(tau_i*s + 1)/(tau_i*s*(tau_p*s+1));   % Continuous
Cpid_d = c2d(Cpid,ts,'tustin');                                 % Discrete

%% Plant P 
m_eq = 0.15;
d_eq = 0.7;
k_eq = 41.5;
P = 1/(m_eq*s^2 + d_eq*s + k_eq);

% Check stability
margin(P*Cpid)

%% Reference (multisine)
%
band = [0.1,5];
N    = 2;
bin  = 0.1;

[u,freq,amplitude] = multisine(ts,band,N,bin,'Periods',20,'Amplitude',2);
u_in = [zeros(1,20/ts),u,zeros(1,5/ts)];
t = [0:(size(u_in,2)-1)]*ts;
t_end = t(end);

reference.time = t';
reference.signals.values = u_in';
reference.dimensions = [1,1];
%}
%% Reference (Random SkewSine)
seed  = 35;
sp_ts = 2.5;
tm    = 2;
ampl  = 10;
t_end = 200;

T = 0:sp_ts:t_end;
M = (t_end-20)/sp_ts

%% Random skewsine referenence 1
sim('skewSine')

skewSine.time = ref.r.Time;
%skewSine.signals.values = [ref.r.Data,ref.r_dot.Data,ref.r_ddot.Data];
skewSine.signals.values = [ref.r.Data];
skewSine.signals.dimensions = [1];

skewSineFF.time = ref.r.Time;
skewSineFF.signals.values = [ref.r.Data,ref.r_dot.Data,ref.r_ddot.Data];
skewSineFF.signals.dimensions = [3];

%%
%{
% Setpoint current
L   = length(ref.r.Time);                  %    Length of signal
Y   = fft(ref.r.Data);                   % Fast fourier transform
f   = (1/ts)*(0:(L/2))/L;           % [Hz] Frequency vector
P2  = abs(Y/L);                 % Normalize
% Single right side
skewsine_FFT  = P2(1:L/2+1);              
skewsine_FFT(2:end-1) = 2*skewsine_FFT(2:end-1);

figure(5),clf(5)
plot(f,skewsine_FFT)
ylim([0 1.1*max(skewsine_FFT)])
xlim([0 35])
title(['Spectrum of u(t)'])
xlabel('f (Hz)')
ylabel('|U(f)|')
%}

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
crossover = 15;
[mag,phase,wout] = bode(SVF,crossover);
svf_delay = -(phase)/(2*pi*wout);
svf_delay = round(svf_delay/(ts*10));
fprintf('\nDelay introduced by State Variable Filter (at crossover): %i timesteps\n',svf_delay)

%% I-SSGP 
Q  = 1;         % [-] Number of latent functions
D  = 21;        % [-] Number of features
n  = 3;         % [-] Input dimensions

% I_SP
sf = 172.95 
sn = 0.4695 
l  = [0.44 5.17 483.23]

%
sf = 124.23 
sn = 5.3379 
l  = [0.61 11.34 1076.15]

%GOOD ONE
sf = 185.90 
sn = 1.68 
l  = [0.70 15.99 369.70]

% Another good one
% sf = 131.82 
% sn = 0.6283 
% l  = [0.76 7.73 319.00]

hyp   = [l,sf];  %Hyperparameters

% Initialize matrices and vectors
R = eye(2*D,2*D)*sn^2;
w = ones(2*D,Q)*0.001;
b = ones(2*D,Q)*0.001;
v = ones(2*D,Q)*0.001;
RAND = randn(D,n);

%% Using optimized spectral points
%
RAND = [-1.9712   -1.7649    0.2886
   -0.1056   -0.9135   -0.9152
   -0.6123    0.0671   -1.4159
    0.9621   -0.2110   -0.3886
    0.3574    0.1900   -2.2347
   -0.0944   -0.0449    0.6470
    0.9639   -0.2933   -1.3333
   -0.0552    0.9375   -1.9636
   -5.0267   -1.1540   -0.8642
   -0.4261   -0.2647    0.0351
    1.4269   -0.0313   -0.3188
   -3.2156    0.0633    2.1825
    0.0223   -0.5566   -0.2196
    1.7344   -1.5982   -0.9071
   -0.4354   -0.9332    0.6683
    2.6647    0.0837    0.6160
   -3.1181    0.2169   -0.9178
    0.0426   -1.9241   -0.1738
    0.4056    0.6532   -1.1749
    0.3678   -0.6163   -0.4550
    1.7861   -1.2340   -0.2979];
%}
SIGMA(1:D,1:n) = RAND.*(1./hyp(1:n));

% Define mean and variance to normalize data
mu_Y  = 0;
sig_Y = 1;

mu_X  = [0,0,0];
sig_X = [1,1,1];


