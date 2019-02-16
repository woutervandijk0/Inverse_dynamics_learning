clc, clear all, close all

fs = 1000;      %Sample rate [Hz]
ts = 1/fs;      %Sample time [s]

g = 0;
L1 = 1;
L2 = 1;
r1 = L1/2;
r2 = L2/2;
m1 = 1;
m2 = 1;
I1 = 1/12*m1*L1^2;
I2 = 1/12*m2*L2^2;

param = [L1,L2,r1,r2,m1,m2,I1,I2];

% initial conditions:
theta1_0 = -180
theta2_0 = 0

C_d1 = 0;
C_k1 = 0;
C_d2 = 0;
C_k2 = 0;


%% Feedback Controllers
PID(1).kp = 0.47399;
PID(1).ki = 53.44;
PID(1).kd = 30.9;
PID(1).N = 234.8;
PID(1).sign = 1;

PID(2).kp = 0.474;
PID(2).ki = 0.0202;
PID(2).kd = 2.471;
PID(2).N = 835;
PID(2).sign = 1;

%Feedforward controller

signFF1 = 1;
signFF2 = 1;


