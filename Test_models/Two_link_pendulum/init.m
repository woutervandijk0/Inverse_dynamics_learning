%clc, clear all, close all
clearvars -except w b v R SIGMA D
%% Add path to GPML toolbox
pathGPML        = 'C:\Users\wout7\Documents\GitHub\gpml\startup.m';
pathGPstuff     = 'C:\Users\wout7\Documents\GitHub\gpstuff\startup.m';
pathSuiteSparse = 'C:\Users\wout7\Documents\GitHub\suitesparse\SuiteSparse_install.m'
run(pathGPML)
run(pathGPstuff)
%run(pathSuiteSparse)
%% Simulink Parameters
fs = 1000;      % [Hz] Sample rate
ts = 1/fs;      % [s]  Sample time
fs_store = 50;         % [Hz] Sample rate of data storage (Downsampling for speed)
ts_store = 1/fs_store   % [s]  Sample time of data storage 

%% Model parameters
g  = 0;             % [m/s^2] Gravtitational acceleration
L1 = 1;             % [m] Length link 1
L2 = 1;             % [m] Length link 2
r1 = L1/2;          % [m] Distance to center of mass 1
r2 = L2/2;          % [m] Distance to center of mass 2
m1 = 1;             % [kg] Mass link 1
m2 = 1;             % [kg] mass link 2
I1 = 1/12*m1*L1^2;  % [kg*m^2] Moment of inertia link 1
I2 = 1/12*m2*L2^2;  % [kg*m^2] Moment of inertia link 2

% Initial conditions (t=0):
theta1_0 = 0;  % [deg] Rotation link 1
theta2_0 = 0;     % [deg]

% Joint parameters
% Stiffness
C_d1 = 1;
C_d2 = 0;
%Damping
C_k1 = 0;
C_k2 = 0;

%% Feedback Controllers
%First DoF
PID(1).kp = 10634.2379%0.47399;
PID(1).ki = 73528.7255%53.44;
PID(1).kd = 377.7742%30.9;
PID(1).N = 793.892%234.8;
PID(1).sign = 1;

%Second DoF
PID(2).kp = 186%0.474;
PID(2).ki = 499%0.0202;
PID(2).kd = 13.35%2.471;
PID(2).N = 140%835;
PID(2).sign = 1;

%Feedforward controller
FF(1).sign = 1;
param = [L1,L2,r1,r2,m1,m2,I1,I2];
%Learning FF:
FF(2).sign = 1;
sigma_f = 0;

%% Online Sparse Gaussian Process regression
Q  = 2;
%D  = 100;
n  = 6;
trainIter = 1;
alpha = 1.5

dataID = 'DoublePendulum.mat'
[sn, sf, ell] = loadHyperparams(dataID,false);
disp([char(10),'Hyperparams loaded for: ',dataID])
disp(['ell: ',num2str(ell(1,:))])
disp(['sf : ',num2str(sf(1:Q)')]);
disp(['sn : ',num2str(sn(1:Q)'),char(10)]);
hyp     =   [ell(:,1:n),sf];

%{
RAND  = randn(D,n);
R = zeros(Q,2*D,2*D);
for i = 1:Q
    R(i,:,:) = eye(2*D,2*D)*sn(Q);
    SIGMA(i,1:D,1:n) = RAND.*hyp(i,1:n);
end
w    = ones(2*D,Q)*0.001;
b    = ones(2*D,Q)*0.001;
v    = ones(2*D,Q)*0.001;
%}

%SIGMA_1 = squeeze(SIGMA(1,:,:));
%SIGMA_2 = squeeze(SIGMA(2,:,:));
%% normalization
[X,Y,ts,N_io] = selectData('dataset',dataID,'fig',false,'figNum',1);
mu_X  = mean(X);
sig_X = std(X);



%% Prior

%% Define GP Prior
% N_search = 20;    %Max iterations of gradient descent
% iN = 6;         %Input dimensions
% cov = {@covSEard}; sf = 2; ell = 2.0; 
% ll = [0.9,    1482.5,    1130.1,    1.9,    42.1,    7747.9,    0.0014]
% %hyp.cov = log([ell*ones(iN,1);sf]);
% %hyp.cov = [-0.0986, 7.3015, 7.0300, 0.6236, 3.7398, 8.9552, 0.3298];
% mean = @meanZero;% hyp.mean = 0;
% sn = 0.5
% lik = {@likGauss};    hyp.lik = log(sn); 
% inf = @infGaussLik;
% load('inputs.mat')
% xu = X(:,indi)';
% cov = {'apxSparse',cov,xu};
% hyp.xu = xu;
% hyp2 = hyp;

%% Save workspace data
%{
X = input_train.Data
Y = target_train.Data
Xsp = [setpoint.Data]
Y = target_train.Data
save('Data/InverseDynamics/DoublePendulum.mat','X','Y')
save('Data/InverseDynamics/DoublePendulumsp.mat','Xsp')
%}

%% plot results
ist = 1000;
%{
figure(152),clf(152)
ha41 = subplot(4,1,1)
hold on
plot(Error(ist:end,1),Error(ist:end,2))
plot(Error(ist:end,1),Error(ist:end,3))
plot([10 10],[-0.06 0.06],'--k')
plot([20 20],[-0.06 0.06],'--k')
title('I-SSGP Feedforward 1-step ahead prediction')
legend('\theta_1','\theta_2')
ylabel('Error (rad)')
hold off

ha42 = subplot(4,1,2)
hold on 
plot(ControlOutput(ist:end,1),ControlOutput(ist:end,2))
plot(ControlOutput(ist:end,1),ControlOutput(ist:end,3))
plot([10 10],[-50 50],'--k')
plot([20 20],[-50 50],'--k')
legend('u_1','u_2')
ylabel('Control output (Nm)')
hold off

ha43 = subplot(4,1,3)
hold on 
plot(FF_SSGP(ist:end,1),FF_SSGP(ist:end,2))
plot(FF_SSGP(ist:end,1),FF_SSGP(ist:end,3))
plot([10 10],[-100 150],'--k')
plot([20 20],[-100 150],'--k')
legend('FF_1','FF_2')
ylabel('SSGP FF predictions (Nm)')
xlabel('time (s)')
hold off

ha44 = subplot(4,1,4)
hold on
plot(torqueError(ist:end,1),torqueError(ist:end,2))
plot(torqueError(ist:end,1),torqueError(ist:end,3))
plot([10 10],[-50 50],'--k')
plot([20 20],[-50 50],'--k')
legend('\theta_1','\theta_2')
ylabel('\tau_{true} - \tau_{pred.} (Nm)')
hold off
linkaxes([ha41,ha42,ha43,ha44],'x')
set(gcf,'Color','w')
%}