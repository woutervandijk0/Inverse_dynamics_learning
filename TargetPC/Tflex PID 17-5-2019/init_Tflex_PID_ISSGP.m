clc, clear all, close all

%% Simulation constants
%PDO MAPPING FIL: C:\Users\Mark\Desktop\tflex\simulink\custom_pdo_eni3.xml;

%% Driver constants
Avout = 10000; %[mV] Analog output voltage used to power KTY temperature sensor (10000mV max)
FB1_offset = 1411500000; %Zero position offset in pulses (/(2^32)*360 for offset in degrees)

%transformation from measured volts to degrees celcius for KTY temperature sensor
%T = KTY_p0 + KTY_p1 * V_in + KTY_p2 * V_in^2
KTY_p0 = -146;%-0.552/0.00385;
KTY_p1 =  263.3;%1/0.00385;

%% Time settings
fs = 4000;      % [Hz] Sample rate
ts = 1/fs;      % [s]  Sample time
t_switch  = 10; % [s]  Time interval over which the I-SSGP is turned on

%% PID
I_limit_max = 750; % [mA]   Current limit (Max.)
I_limit_min = -250;% [mA]   Current limit (Min.)
gainMotor = 5.56;  % [Nm/A] Motor constant

crossOver = 15*2*pi;     %[rad/s]
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
s = tf('s');
LP = 1/(tau_p*s+1);         % Continuous
LP_d = c2d(LP,ts);          % Discrete
[LPnum,LPden] = tfdata(LP_d,'v');



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
fprintf('\nDelay introduced by State Variable Filter: %i timesteps\n',svf_delay)

%% I-SSGP 
Q  = 1;         % [-] Number of latent functions
D  = 30;        % [-] Number of features
n  = 3;         % [-] Input dimensions

sn    = 2;       % Signal noise
%Hyperparameters
ell   = [-0.1564, 0.0772, -0.2425];
%ell   = [1,1,1];   % Length scales
sf    = 0.5244;
%sf    = [1];       % 
hyp   = [ell,sf];  %Hyperparameters

% Initialize matrices and vectors
R = eye(2*D,2*D)*sn;
w = ones(2*D,Q)*0.001;
b = ones(2*D,Q)*0.001;
v = ones(2*D,Q)*0.001;
RAND = randn(D,n);
SIGMA(1:D,1:n) = RAND.*hyp(1:n);

% Define mean and variance to normalize data
mu_Y  = 0;
sig_Y = 1;

mu_X  = [0,0,0];
sig_X = [1,1,1];

%% Setpoint Generator
seed  = 48125;      % Seed for Uniform Random Number

sp_ts = 5;    % [s] Step size of setpoint
tm    = 4;      % [s] Settle time of setpoint generator

%Transient reference generator
r = 1e2;
h = 10*ts;

