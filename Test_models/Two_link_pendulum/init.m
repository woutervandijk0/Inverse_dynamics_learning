clear all, %close all,% clc
%clearvars -except w b v R SIGMA D
model = 'Coupled_GP_fit';

FF_rbd = 0; 
%% Simulink Parameters
fs = 1000;      % [Hz] Sample rate
ts = 1/fs;      % [s]  Sample time
ts_opti   = ts*100;
t_end     = 150;
t_start   = 15;
t_learn   = 0;   %[s] Switch for updating the posterior
t_predict = 50;
t_switch  = 5;          % [s]  Time interval over which the I-SSGP is turned on
reference_switch = t_end;

%setpoint generator
seed = randi(1e6);
r = 5e3;
h = 1;
sp_ts = 2.5
tm = 2;         %settle time


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
D  = 21;
n  = 6;

% Hyperparameters DoF 1
% Hyperparameters DoF 1
sf_1 = 219.77;
sn_1 = 1.0478;
l_1  = [0.25 0.25 2.06 0.49 21.76 244.34];

% Hyperparameters DoF 2
sf_2 = 2018.77;
sn_2 = 0.4620;
l_2  = [0.50 29.46 1.01 2.44 194.14 408.76];

sn = [sn_1; sn_2];
sf = [sf_1; sf_2];
l  = [l_1 ; l_2 ];

hyp   = [l,sf]

%% state variable filter
omega_n = 50*2*pi;
a0 = omega_n^3;
a1 = 3*omega_n^2;
a2 = 3*omega_n;

%%
RAND  = randn(Q,D,n);
RAND_1 = squeeze(RAND(1,:,:));
RAND_2 = squeeze(RAND(1,:,:));

%
RAND_1 = [-0.4298    0.9223    1.5027    0.7258    1.3232   -0.4314
    0.3723   -2.6737    0.0908    0.2726    0.0169    0.7768
   -0.4686   -0.5509    0.5850   -0.1073    0.2696   -0.6515
    0.6427    0.5488    1.0148   -0.4391    0.2796    0.8781
    0.4924    1.0745   -0.8509    1.0176    1.5640    0.3568
    1.6080   -0.1054   -1.7861   -1.9522   -2.4573    0.1986
    0.5199    0.8757   -1.3321   -0.0721   -1.7568    0.9789
   -0.3276   -1.4018    0.2376    0.0480    1.2935    2.3240
   -0.1431   -1.5359   -0.6063    0.2654    1.7641    1.2439
   -1.0706    0.4093    0.7558   -1.1540   -0.2503   -1.5898
   -0.5358   -0.4778   -0.2138   -1.5428    1.2892    0.5765
   -0.7391   -0.2506   -1.2894   -2.7355    2.1950   -1.2584
   -1.0221   -0.8706    0.5309   -1.0448    0.1468   -1.8862
   -0.1234   -0.0497    1.2899    1.1667   -0.9354   -0.9131
   -0.5564   -0.0392   -0.0206   -0.5468   -0.6519   -2.1640
   -1.1712    1.8119   -0.2664    2.7313   -0.2959   -1.1307
   -0.3211    1.5282   -0.3774   -0.7787    0.9191    1.3317
    0.5076    0.8382    1.1024   -1.2251   -0.0544   -0.5257
   -1.1795    1.4081    0.9849   -0.2280    2.0301    2.6832
    0.4115   -1.4815   -0.4614   -0.4190   -0.1972    0.3837
   -0.4320    1.4081   -1.1968    0.0792   -0.8429    1.0286    ];
RAND_2 = [-0.2780    0.7288    1.7482    0.7267    1.4111   -0.4298
   -0.9261   -1.0794   -0.6164    0.9462   -0.0928    0.7639
   -0.0525    0.0535    0.9110   -0.1114    0.0549   -0.7709
    1.7834    0.2055    0.0393   -0.1064    0.2524    0.6753
   -0.1717    1.5970   -1.0701    0.9184    1.3616    0.3105
    0.6999    0.5221   -1.8863   -1.7584   -2.4277    0.1931
    1.4999    0.0236   -1.4645    0.0542   -1.7381    1.0212
   -0.3508   -1.4364    0.3417   -0.1125    1.4700    2.0571
   -0.4428   -1.5166   -0.3158    0.3789    1.8414    1.4353
   -1.5182    0.5853    0.5968   -0.8079   -0.2327   -1.5826
   -0.0704   -0.7309   -0.2349   -1.2941    1.3824    0.4085
   -0.9722   -0.2665   -1.6234   -2.5581    2.1402   -1.2665
   -0.2741   -0.8214   -0.1434    0.4862    0.0694   -2.0356
   -0.4920    0.2128    1.0923    1.0676   -0.4933   -1.2338
   -0.6171    0.3051    0.3653   -0.5044   -0.4302   -2.2200
   -1.3013    1.7685    0.1157    2.4012   -0.1982   -1.1579
    0.1844    2.0012    0.1090   -0.7829    0.7509    1.2493
    0.4578    1.1149    1.1146   -1.2334   -0.2283   -0.4882
   -1.0335    1.0983    1.1231   -0.1559    1.8605    2.7277
    0.2009   -1.3100   -0.0879   -0.3664   -0.1420    0.3020
   -0.4102    1.2898   -1.0673    0.5633   -0.6978    1.0327    ];
%}

RAND(1,:,:) = RAND_1;
RAND(2,:,:) = RAND_2;
%
R = zeros(Q,2*D,2*D);
for i = 1:Q
    R(i,:,:) = eye(2*D,2*D)*sn(i);
    SIGMA(i,1:D,1:n) = squeeze(RAND(i,:,:)).*(1./hyp(i,1:n));
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
noise.torque.power(1) = 100;
noise.torque.power(2) = 100;
noise.torque.gain(1)  = 1e-3;
noise.torque.gain(2)  = 1e-3;

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
m2 = 5;             % [kg] mass link 2
I1 = 1/12*m1*L1^2;  % [kg*m^2] Moment of inertia link 1
I2 = 1/12*m2*L2^2;  % [kg*m^2] Moment of inertia link 2

% Initial conditions (t=0):
theta1_0 = 0;  % [deg] Rotation link 1
theta2_0 = 0;  % [deg]

% Joint parameters
% Stiffness
C_d1 = 2;
C_d2 = 1;
%Damping
C_k1 = 1;
C_k2 = 5;

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
sig_X = ones(1,size(n,2))% std(X);

%mu_Y  = mean(Y);
%sig_Y = std(Y);
mu_Y  = zeros(1,size(Q,2));
sig_Y = ones(1,size(n,2))% std(Y);

%% Run simulink model
tic
sim(model)
toc

%% Save workspace data
%
X = squeeze(xTraining(:,1,:))';
Y = yTraining;
Xsp = squeeze(reference(:,1,:))';
%{
save('Data/InverseDynamics/DoublePendulumRand.mat','X','Y');
save('Data/InverseDynamics/DoublePendulumRandsp.mat','Xsp');
%}
t = [0:length(X)-1]'.*ts;
Error = squeeze(error(:,1,:))';
Error = error;
%ControlOutput = [ControlOutput.time, squeeze(ControlOutput.signals.values(:,1,:))'];
FF_SSGP = [FF_SSGP];
FF_RBD = [FF_RBD];
torqueError = Y;

%% plot results
fontSize   = 8;
labelSize  = 11;
legendSize = 8;

xLim = [0 100];

results = figure(152); clf(results);
han(1,1) = subplot(4,1,1);
set(gca,'FontSize',fontSize);
hold on
plot(t,Error(:,1))
plot(t,Error(:,2))
%title(['I-SSGP Feedforward 1-step ahead prediction ','(D=',num2str(D),')'])
legend('$\theta_1$','$\theta_2$','Interpreter','Latex','FontSize',labelSize)
ylabel('$e$ (rad)','Interpreter','Latex','FontSize',labelSize)
xlim(xLim)
%ylim([-0.08 0.08])
hold off

han(2,1) = subplot(3,1,2);
set(gca,'FontSize',fontSize);
hold on 
plot(t,FB(:,1))
plot(t,FB(:,2))
legend('$u_{FB,1}$','$u_{FB,2}$','Interpreter','Latex','FontSize',labelSize)
ylabel('$u_{FB}$ (Nm)','Interpreter','Latex','FontSize',labelSize)
xlim(xLim)
hold off

han(3,1) = subplot(3,1,3);
set(gca,'FontSize',fontSize);
hold on 
plot(t,FF_SSGP(:,1))
plot(t,FF_SSGP(:,2))
legend('$u_{FF,1}$','$u_{FF,2}$','Interpreter','Latex','FontSize',labelSize)
ylabel('$u_{FF}$ (Nm)','Interpreter','Latex','FontSize',labelSize)
xlabel('t (s)','Interpreter','Latex','FontSize',labelSize)
xlim(xLim)
hold off

%{
han(3,1) = subplot(4,1,3);
hold on 
plot(t(ist:end,1),FF_RBD(ist:end,1))
plot(t(ist:end,1),FF_RBD(ist:end,2))
legend('$FF_{RBD,1}$','$FF_{RBD,2}$','Interpreter','Latex')
ylabel('RBD FF (Nm)')
hold off
%}
%{
han(4,1) = subplot(4,1,4);
hold on
plot(t(ist:end,1),torqueError(ist:end,1))
plot(t(ist:end,1),torqueError(ist:end,2))
legend('\theta_1','\theta_2','Interpreter','Latex')
ylabel('\tau_{true} - \tau_{pred.} (Nm)','Interpreter','Latex')
xlabel('time (s)','Interpreter','Latex')
hold off
%}
[results,han] = subplots(results,han,'gabSize',[0.09, 0.04]);
set(gcf,'PaperSize',[8.4 8.4*3/4+0.1],'PaperPosition',[0.2 0.2 8.4 8.4*3/4+0.2])
%%
saveFig = 1;
if saveFig == 1
    saveas(results,fullfile(pwd,'Images','2DoF_ISSGP.pdf'))
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end
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
plot(t,FF_SSGP(:,1),'r')
ylabel('(N m)')
hold off

ha(5) = subplot(7,1,6:7);
hold on
plot(t,FF_SSGP(:,2),'b')
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