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
fs = 1000;      % [Hz] Sample rate
ts = 1/fs;      % [s]  Sample time
t_switch  = 10; % [s]  Time interval over which the I-SSGP is turned on

%% PID controller
W_c = 35*2*pi;          % [rad/s] Cross over frequency

alpha = 0.1;            %
beta  = 10;             %
m_eq  = 0.2;            % Equivalent mass

kp    = m_eq*W_c^2/sqrt(1/alpha)
tau_z = sqrt(1/alpha)/W_c
tau_i = beta*tau_z
tau_p = 1/(sqrt(1/alpha)*W_c)

%% State variable filter
W_n = 50*2*pi;  % [rad/s] Natural frequency

a0 = W_n^3;
a1 = 3*W_n^2;
a2 = 3*W_n;

%% I-SSGP
Q  = 1;         % [-] Number of latent functions
D  = 20;        % [-] Number of features
n  = 3;         % [-] Input dimensions

sn    = 1;       % Signal noise
%Hyperparameters
ell   = [-0.1564, 0.0772, -0.2425];
ell   = [1,1,1];   % Length scales
sf    = 0.5244;
sf    = [1];       % 
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
seed  = 1;      % Seed for Uniform Random Number
sp_ts = 1.5;    % [s] Step size of setpoint
tm    = 1;      % [s] Settle time of setpoint generator

%% Limits
I_limit = 2000;  % [mA] Max/min current


