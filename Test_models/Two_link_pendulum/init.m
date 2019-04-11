clear all, %close all,% clc
%clearvars -except w b v R SIGMA D
model = 'Coupled_GP_fit';

%% Simulink Parameters
fs = 1000;      % [Hz] Sample rate
ts = 1/fs;      % [s]  Sample time
t_end     = 30;
t_learn   = [2 20 t_end];   %[s] Switch for updating the posterior 
t_predict = [2];

%% Online Sparse Gaussian Process regression
Q  = 2;
D  = 50;
n  = 6;
alpha = 1;

sn = [9.2736;5.2731];
sn = [1;1];
%sn = [7;7];
%sn = [5.2731;5.2731];


dataID = 'DoublePendulum.mat'
[~, sf, ell] = loadHyperparams(dataID,false);
disp([char(10),'Hyperparams loaded for: ',dataID])
disp(['ell: ',num2str(ell(1,:))])
disp(['sf : ',num2str(sf(1:Q)')]);
disp(['sn : ',num2str(sn(1:Q)'),char(10)]);
hyp     =   [ell(:,1:n),sf];



%%
%
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

w1 = w(:,1);
w2 = w(:,2);

b1 = b(:,1);
b2 = b(:,2);

R1 = squeeze(R(1,:,:));
R2 = squeeze(R(2,:,:));

SIGMA1 = squeeze(SIGMA(1,:,:));
SIGMA2 = squeeze(SIGMA(2,:,:));

sf1 = sf(1);
sf2 = sf(2);

%% Disturbances
% Signal noise
noise.signal.power(1) = 0.1;
noise.signal.power(2) = 0.1;
noise.signal.gain(1)  = 0;%1e-8;
noise.signal.gain(2)  = 0;%1e-8;

% Torque disturbance
noise.torque.power(1) = 0.1;
noise.torque.power(2) = 0.1;
noise.torque.gain(1)  = 1;
noise.torque.gain(2)  = 1;

%Sample time;
noise.sampleTime(1) = 1/10;
noise.sampleTime(2) = ts;


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
theta2_0 = 0;  % [deg]

% Joint parameters
% Stiffness
C_d1 = 1;
C_d2 = 0;
%Damping
C_k1 = 0;
C_k2 = 0;

%setpoint generator
r = 1e3;
h = 0.01;

%% Feedback Controllers
%First DoF
PID(1).kp = 10634.2379;
PID(1).ki = 73528.7255;
PID(1).kd = 377.7742;
PID(1).N = 793.892;
PID(1).sign = 1;

%Second DoF
PID(2).kp = 186;
PID(2).ki = 499;
PID(2).kd = 13.35;
PID(2).N = 140;
PID(2).sign = 1;

%Feedforward controller
FF(1).sign = 1;
param = [L1,L2,r1,r2,m1,m2,I1,I2];
%Learning FF:
FF(2).sign = 1;

%% normalization
[X,Y,ts,N_io] = selectData('dataset',dataID,'fig',false,'figNum',1);
mu_X  = mean(X);
sig_X = std(X);

mu_Y  = mean(Y);
sig_Y = std(Y);

%% Switch on/off I-SSGP algorithm
t_learn   = [0, t_learn]';
t_predict = [0, t_predict]';
y = [0 1 0 1 0 1 0 1 0 1 0 1 0 1 0]';

learn.time = t_learn;
learn.signals.values = [y(1:length(t_learn))];
learn.signals.dimensions = 1;

predict.time = t_predict;
predict.signals.values = [y(1:length(t_predict))];
predict.signals.dimensions = 1;

%% Run simulink model
tic
set_param(model,'Profile','off')
sim(model)
toc

%% Data Copy Reduction for Data Store Read and Data Store Write Blocks
%{
model='Coupled_GP_fit';
open_system(model);
set_param(model,'OptimizeDataStoreBuffers','off');

currentDir = pwd;
[~,cgDir] = rtwdemodir();
rtwbuild(model)

cfile = fullfile(cgDir,[model,'_grt_rtw'],...
    [model,'.c']);
rtwdemodbtype(cfile,'/* Model step', '/* Model initialize', 1, 0);

pathEXE = [cgDir,'\',model,'.exe'];
fullCommand = [pathEXE,' &']
system(fullCommand);
cd(currentDir)
%}
%{
fileID = 'Coupled_GP_fit.mat';
fullPath = [cgDir,'\',model,'.mat'];
load(fullPath)

t = rt_Error(:,1);
error = rt_Error(:,2:3);
figure(999),clf(999)
plot(t,error)
%}

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
ist  = 1000;
tOn1 = t_learn;
tOn2 = t_end;
t1 = [tOn1 tOn1];
t2 = [tOn2 tOn2];

%
figure(152),clf(152)
ha41 = subplot(4,1,1);
hold on
plot(Error(ist:end,1),Error(ist:end,2))
plot(Error(ist:end,1),Error(ist:end,3))
ylimit(1) = min([Error(ist:end,2);Error(ist:end,3)]);
ylimit(2) = max([Error(ist:end,2);Error(ist:end,3)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
title(['I-SSGP Feedforward 1-step ahead prediction ','(D=',num2str(D),')'])
legend('\theta_1','\theta_2')
ylabel('Error (rad)')
hold off

ha42 = subplot(4,1,2);
hold on 
plot(ControlOutput(ist:end,1),ControlOutput(ist:end,2))
plot(ControlOutput(ist:end,1),ControlOutput(ist:end,3))
ylimit(1) = min([ControlOutput(ist:end,2);ControlOutput(ist:end,3)]);
ylimit(2) = max([ControlOutput(ist:end,2);ControlOutput(ist:end,3)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
legend('u_1','u_2')
ylabel('Control output (Nm)')
hold off

ha43 = subplot(4,1,3);
hold on 
plot(FF_SSGP(ist:end,1),FF_SSGP(ist:end,2))
plot(FF_SSGP(ist:end,1),FF_SSGP(ist:end,3))
ylimit(1) = min([FF_SSGP(ist:end,2);FF_SSGP(ist:end,3)]);
ylimit(2) = max([FF_SSGP(ist:end,2);FF_SSGP(ist:end,3)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
legend('FF_1','FF_2')
ylabel('SSGP FF predictions (Nm)')
xlabel('time (s)')
hold off

ha44 = subplot(4,1,4);
hold on
plot(torqueError(ist:end,1),torqueError(ist:end,2))
plot(torqueError(ist:end,1),torqueError(ist:end,3))
ylimit(1) = min([torqueError(ist:end,2);torqueError(ist:end,3)]);
ylimit(2) = max([torqueError(ist:end,2);torqueError(ist:end,3)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
legend('\theta_1','\theta_2')
ylabel('\tau_{true} - \tau_{pred.} (Nm)')
xlabel('time (s)')
hold off
linkaxes([ha41,ha42,ha43,ha44],'x')
set(gcf,'Color','w')
%}

%% Plot output
Y = input_train.Data;
t = target_train.Time;

figure(888), clf(888)
subplot(3,1,1)
hold on
plot(t,Y(:,1))
plot(t,Y(:,2))
hold off
%ylim([-150 150])
ylabel('Rotation (rad)')

subplot(3,1,2)
hold on
plot(t,Y(:,3))
plot(t,Y(:,4))
hold off
%ylim([-150 150])
ylabel('velocity (rad/s)')

subplot(3,1,3)
hold on
plot(t,Y(:,5))
plot(t,Y(:,6))
hold off
ylim([-150 150])
ylabel('Angular acceleration (rad/s^2)')
xlabel('time (s)')
