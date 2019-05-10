clear all, %close all,% clc
%clearvars -except w b v R SIGMA D
model = 'Coupled_GP_fit';

FF_rbd = 0; 
%% Simulink Parameters
fs = 1000;      % [Hz] Sample rate
ts = 1/fs;      % [s]  Sample time
ts_opti = ts*100
t_end     = 150;
t_start   = 15;
t_learn   = [t_start t_end];   %[s] Switch for updating the posterior
t_predict = [t_start+10];
t_hypUpdate = [t_start t_end];
t_switch  = 5;          % [s]  Time interval over which the I-SSGP is turned on
reference_switch = t_end

%setpoint generator
seed = randi(1e6);
r = 5e3;
h = 1;
sp_ts = 1.5
tm = 1;         %settle time


%r = 5e4;
%h = 1e-3;
%{
%some tests:
limits.v = 1;
limits.a = 10;
limits.j = 0.5;
sp = [0, randi(80,[1,200])-40].*pi./180;
sp_abs = sp(1:end-1)-sp(2:end);
t_sp = [0,1];
t_sp2 = [0,1];

j_sp = [0,0];
a_sp = [0,0];
t_pauze = 1;
for tt = 1:length(sp_abs)
    p = sp_abs(tt);
    if p ~= 0
        
        [t,jd] = make3(p,limits.v,limits.a,limits.j,ts)
        
        t_vec = [0, 0, t(1), t(1), t(1)+t(2), t(1)+t(2), 2*t(1)+t(2), 2*t(1)+t(2), 2*t(1)+t(2)+t(3), ...
            2*t(1)+t(2)+t(3), 3*t(1)+t(2)+t(3), 3*t(1)+t(2)+t(3), 3*t(1)+2*t(2)+t(3), 3*t(1)+2*t(2)+t(3),...
            4*t(1)+2*t(2)+t(3), 4*t(1)+2*t(2)+t(3), 4*t(1)+2*t(2)+t(3)+t_pauze] + max(t_sp);
        j_vec = [0, limits.j, limits.j, 0, 0, -limits.j, -limits.j, 0, 0,...
            -limits.j, -limits.j, 0, 0, limits.j,...
            limits.j, 0, 0];
        
        t_vec2= [0,     t(1), t(1)+t(2), 2*t(1)+t(2), 2*t(1)+t(2)+t(3), 3*t(1)+t(2)+t(3), ...
            3*t(1)+2*t(2)+t(3), 4*t(1)+2*t(2)+t(3), 4*t(1)+2*t(2)+t(3)+t_pauze] + max(t_sp2);
        a_vec = [0, limits.a,  limits.a,           0,                0,        -limits.a, ...
            -limits.a,                  0,                          0];
        t_sp = [t_sp,t_vec];
        t_sp2 = [t_sp2,t_vec2];
        
        j_sp = [j_sp,j_vec.*sign(sp_abs(tt))];
        a_sp = [a_sp,a_vec.*sign(sp_abs(tt))];
    end
end
figure(100),clf(100)
subplot(3,1,1)
stairs(sp)
subplot(3,1,2)
plot(t_sp2)
subplot(3,1,3)
plot(t_sp2,a_sp)
drawnow

acceleration.time = t_sp';
acceleration.signals.values = cumtrapz(t_sp, j_sp)';
acceleration.signals.dimensions = 1;
%}

%% Online Sparse Gaussian Process regression
Q  = 2;
D  = 50;
Z  = 2000;
Z_resamp = 100;
n  = 6;
alpha = 1;

sn = [9.2736;5.2731];
sn = [5.2731;5.2731];
%sn  = [1;1]
%sn  = [0.5;0.5]
sn = [0.1;0.1]
sn = [0.0244;0.0672];
%sn = [0.01;0.01]

%dataID = 'DoublePendulum.mat'
dataID  = 'DoublePendulumRand.mat'
%dataID  = 'DoublePendulumRand1.mat'

[~, sf, ell] = loadHyperparams(dataID,false);
disp([char(10),'Hyperparams loaded for: ',dataID])
disp(['ell: ',num2str(ell(1,:))])
disp(['sf : ',num2str(sf(1:Q)')]);
disp(['sn : ',num2str(sn(1:Q)'),char(10)]);
hyp =   [ell(:,1:n),sf];
hyp(1,:) = 0.1;
% hyp     = [1.7251   -1.6495   -0.0666   -0.4199    0.4007    0.1012    0.1317;
%     0.4891   -3.3727    0.2984   -0.0253    0.2786    0.0600    0.1900];

%% state variable filter
omega_n = 95*2*pi;
a0 = omega_n^3;
a1 = 3*omega_n^2;
a2 = 3*omega_n;


%%
%
RAND  = randn(D,n);
R = zeros(Q,2*D,2*D);
for i = 1:Q
    R(i,:,:) = eye(2*D,2*D)*sn(i);
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
noise.signal.gain(1)  = 1e-6;
noise.signal.gain(2)  = 1e-6;

% Torque disturbance
noise.torque.power(1) = 0.1;
noise.torque.power(2) = 0.1;
noise.torque.gain(1)  = 0e-6;
noise.torque.gain(2)  = 0e-6;

%Sample time;
noise.sampleTime(1) = ts;
noise.sampleTime(2) = ts;

%% Model parameters
g  = 9.81;          % [m/s^2] Gravtitational acceleration
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
C_d2 = 1;
%Damping
C_k1 = 0;
C_k2 = 0;

%% Feedback Controllers
%First DoF
PID(1).kp = 916.2;
PID(1).ki = 1915;
PID(1).kd = 90.4;
PID(1).N = 33.8;
PID(1).sign = 1;

%Second DoF
PID(2).kp = 107.8;
PID(2).ki = 162.5;
PID(2).kd = 16.31;
PID(2).N  = 462.5;
PID(2).sign = 1;

%{
m_eq = 1e3;
crossOver = 100*2*pi;
alpha = 0.1;
beta  = 2;
PID(1).kp    = m_eq*crossOver^2/sqrt(1/alpha)
PID(1).tau_z = sqrt(1/alpha)/crossOver;
PID(1).tau_i = beta*PID(1).tau_z;
PID(1).tau_p = 1/(crossOver*sqrt(1/alpha))

m_eq = 1e3;
crossOver = 100*2*pi;
alpha = 0.1;
beta  = 2;
PID(2).kp    = m_eq*crossOver^2/sqrt(1/alpha)
PID(2).tau_z = sqrt(1/alpha)/crossOver;
PID(2).tau_i = beta*PID(2).tau_z;
PID(2).tau_p = 1/(crossOver*sqrt(1/alpha))
%}

%Feedforward controller
FF(1).sign = 1;
param = [L1,L2,r1,r2,m1,m2,I1,I2];
FF(1).gain = FF_rbd;
%Learning FF:
FF(2).sign = [1 1];
FF(2).gain   = 1;

%% normalization
%[X,Y,ts,N_io] = selectData('dataset',dataID,'fig',false,'figNum',1);
%mu_X  = mean(X);
%sig_X = std(X);
mu_X  = zeros(1,size(n,2));%mean(X);
sig_X = ones(1,size(n,2)).*0.5% std(X);

%mu_Y  = mean(Y);
%sig_Y = std(Y);
mu_Y  = zeros(1,size(Q,2));
sig_Y = [50 15];%std(Y);

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

%% Save workspace data
%
X = squeeze(trainingInput(:,1,:))';
Y = trainingTarget;
Xsp = squeeze(reference(:,1,:))';
%{
save('Data/InverseDynamics/DoublePendulumRand.mat','X','Y');
save('Data/InverseDynamics/DoublePendulumRandsp.mat','Xsp');
%}
t = [0:length(X)-1]'.*ts;
Error = squeeze(error(:,1,:))';
%Error = error;
%ControlOutput = [ControlOutput.time, squeeze(ControlOutput.signals.values(:,1,:))'];
FF_SSGP = [FF_SSGP];
FF_RBD = [FF_RBD];
torqueError = Y;

%% plot results
ist  = 1000;
tOn1 = t_learn;
tOn2 = t_end;
t1 = [tOn1 tOn1];
t2 = [tOn2 tOn2];

figure(152),clf(152)
ha41 = subplot(5,1,1);
hold on
plot(t(ist:end,1),Error(ist:end,1))
plot(t(ist:end,1),Error(ist:end,2))
ylimit(1) = min([Error(ist:end,1);Error(ist:end,2)]);
ylimit(2) = max([Error(ist:end,1);Error(ist:end,2)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
title(['I-SSGP Feedforward 1-step ahead prediction ','(D=',num2str(D),')'])
legend('\theta_1','\theta_2')
ylabel('Error (rad)')
hold off

ha42 = subplot(5,1,2);
hold on 
plot(t(ist:end,1),controlOutput(ist:end,1))
plot(t(ist:end,1),controlOutput(ist:end,2))
ylimit(1) = min([controlOutput(ist:end,1);controlOutput(ist:end,2)]);
ylimit(2) = max([controlOutput(ist:end,1);controlOutput(ist:end,2)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
legend('u_1','u_2')
ylabel('FB (Nm)')
hold off

ha43 = subplot(5,1,3);
hold on 
plot(t(ist:end,1),FF_SSGP(ist:end,1))
plot(t(ist:end,1),FF_SSGP(ist:end,2))
ylimit(1) = min([FF_SSGP(ist:end,1);FF_SSGP(ist:end,2)]);
ylimit(2) = max([FF_SSGP(ist:end,1);FF_SSGP(ist:end,2)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
legend('FF_1','FF_2')
ylabel('I-SSGP FF (Nm)')
hold off

ha44 = subplot(5,1,4);
hold on 
plot(t(ist:end,1),FF_RBD(ist:end,1))
plot(t(ist:end,1),FF_RBD(ist:end,2))
ylimit(1) = min([FF_RBD(ist:end,1);FF_RBD(ist:end,2)]);
ylimit(2) = max([FF_RBD(ist:end,1);FF_RBD(ist:end,2)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
legend('$FF_{RBD,1}$','$FF_{RBD,2}$','Interpreter','Latex')
ylabel('RBD FF (Nm)')
hold off

ha45 = subplot(5,1,5);
hold on
plot(t(ist:end,1),torqueError(ist:end,1))
plot(t(ist:end,1),torqueError(ist:end,2))
ylimit(1) = min([torqueError(ist:end,1);torqueError(ist:end,2)]);
ylimit(2) = max([torqueError(ist:end,1);torqueError(ist:end,2)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
legend('\theta_1','\theta_2')
ylabel('\tau_{true} - \tau_{pred.} (Nm)')
xlabel('time (s)')
hold off
linkaxes([ha41,ha42,ha43,ha44, ha45],'x')
set(gcf,'Color','w')

%}

%% Plot output
%

figure(888), clf(888)
set(gcf,'Color','White')
ah(1) = subplot(4,1,1);
hold on
plot(t,X(:,1))
plot(t,X(:,2))
plot(t,Xsp(:,1),'--')
plot(t,Xsp(:,2),'--')
hold off
title('Training input (1:3), training target (4)')
legend('\theta_1','\theta_2','\theta_{1,sp}','\theta_{2,sp}')
ylabel('(rad)')

ah(2) = subplot(4,1,2);
hold on
plot(t,X(:,3))
plot(t,X(:,4))
plot(t,Xsp(:,3),'--')
plot(t,Xsp(:,4),'--')
hold off
legend('$\dot{\theta_1}$','$\dot{\theta_2}$','$\dot{\theta_{1,sp}}$','$\dot{\theta_{2,sp}}$','Interpreter','Latex')
%ylim([-150 150])
ylabel('(rad/s)')

ah(3) = subplot(4,1,3);
hold on
plot(t,X(:,5))
plot(t,X(:,6))
plot(t,Xsp(:,5),'--')
plot(t,Xsp(:,6),'--')
hold off
%ylim([-150 150])
legend('$\ddot{\theta_1}$','$\ddot{\theta_2}$','$\ddot{\theta_{1,sp}}$','$\ddot{\theta_{2,sp}}$','Interpreter','Latex')
ylabel('(rad/s^2)')
linkaxes([ah],'x')

ah(4) = subplot(4,1,4);
hold on
plot(t,torqueError(:,1))
plot(t,torqueError(:,2))
hold off
%ylim([-150 150])
legend('$T_{true,1}-T_{pred.,1}$','$T_{true,2}-T_{pred.,2}$','Interpreter','Latex')
ylabel('(Nm)')
xlabel('time (s)')
linkaxes([ah],'x')

%%

%Xsp = setpoint.Data;
%P   = FF_SSGP()
%
figure(150),clf(150)
set(gcf,'Color','White')
ha(1) = subplot(7,1,1);
hold on
plot(t,Xsp(:,1),'r')
plot(t,Xsp(:,2),'b')
ylabel('(rad)')
hold off

ha(2) = subplot(7,1,2);
hold on
plot(t,Xsp(:,3),'r')
plot(t,Xsp(:,4),'b')
ylabel('(rad/s)')
hold off

ha(3) = subplot(7,1,3);
hold on
plot(t,Xsp(:,5),'r')
plot(t,Xsp(:,6),'b')
ylabel('(rad/s^2)')
hold off

ha(4) = subplot(7,1,4:5);
hold on
plot(t(ist:end,1),FF_SSGP(ist:end,1),'r')
ylabel('(N m)')
hold off

ha(5) = subplot(7,1,6:7);
hold on
plot(t(ist:end,1),FF_SSGP(ist:end,2),'b')
ylabel('(N m)')
hold off
linkaxes([ha],'x')

% pos = [-1.4022e+03 559.4000 858.4000 488];
% set(figure(152),'Position',pos)
% set(figure(888),'Position',pos)
% set(figure(150),'Position',pos)

%% Noise calculation
noiseSignal = torqueError;
noiseSignal = noiseSignal./sig_Y;
N = length(noiseSignal);
sigma = sqrt(sum((noiseSignal-0).^2)/N);
sigma = sqrt(sigma);

%% Compare error 
i_start = t_start/ts;
i_end = length(X)-i_start;

errorMethod = 'MSE';
disp(' ')
disp('Without I-SSGP:')
[error_wo_issgp] = errorMeasure(Xsp(1:i_start,1:2),X(1:i_start,1:2),'method',errorMethod,'show',true);
disp('With    I-SSGP:')
[error_w_issgp] = errorMeasure(Xsp(i_end:end,1:2),X(i_end:end,1:2),'method',errorMethod,'show',true);
disp('Improvement (%):')
disp([errorMethod,' :   ',num2str(-100+error_w_issgp./error_wo_issgp*100)])
%disp(['improvement: ',num2str(-100+error_w_issgp./error_wo_issgp*100),'%'])


%}