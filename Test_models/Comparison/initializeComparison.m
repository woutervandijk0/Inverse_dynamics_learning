clc, clear all, close all
ts = 1/1000;
Ts = ts;

%% Time settings
t_end       = 200;        %[s] Total simulation time
t_predict   = 20; %[s] Make predictions

%% TFlex plant
s = tf('s');
P = 1/(0.2*s^2 + 0.74*s + 11.46)       %Tflex
P2 = 1/((0.2*s^2 + 0.74*s + 11.46)*(0.000001*s^2 + 0.00001*s + 0.5e3^2*0.00001)); %[mA/deg] Transfer function of Tflex
[Pnum,Pden] = tfdata(P,'v');

%% Reference generator
% Skewsine Reference Generator
seed  = 1; %randi(20000,1); %
sp_ts = 1
tm    = 0.1;

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

%% Cogging 
angle = linspace(-23,23,500);
f = [10, 5, 20, 2.5, 1.25];  % Frequencies
p = [0, 0, -5, 0, 2];        % Phase delay
a = [40, -20, 30, 2, 0.1];   % Amplitude (relative)
cT    = sum( a'.*sin(((angle+p')*2*pi)./f'));
[maxValue,index] = max(cT);
cT    = a'.*sin(((angle(index)+p')*2*pi)./f');
a = a./maxValue;              % Normalized amplitudes 

ampCogging = a;
freqCogging = f;
phaseCogging = p;
%% Run simulation
m_eq  = 0; %No FF
t_sim = 30;
tic;
sim('TFlex_basis')
elap_time = toc;

%% retrieve simulation data
xTrain = trainingInput;
yTrain = trainingTarget;

[dof, N] = size(xTrain');
yTrain  = yTrain(:,1)';
xTrain  = xTrain';
%xTrain(3,:)  = movmean(xTrain(3,:),10);
%xSp = xTrain;
%xSp(3,:)  = movmean(xTrain(3,:),10);

T       = [[0:N-1]*Ts];       % Time 

%% Hyperparameter update using FITC
%Hyperparameters 
sn  = 1;          % Noise variance
sf   = 0.5;           % Signal variance
l    = [ones(1,dof)];   % characteristic lengthscale
%Combine into 1 vector
hyp  = [sf,l];

%% Data selection (intial)
i_f = [1:5:2000];
i_u = [1:5:i_f(end)];
i_s = i_f;

f  = xTrain(:,i_f)';
u  = xTrain(:,i_u)';
s  = xTrain(:,i_s)';

yf = yTrain(:,i_f)';
ys = yTrain(:,i_s)';

Mf  = length(i_f);

figure(888),clf(888)
plot(i_f*Ts,yf)


%% Hyperparameter optimization
disp('Start hyperparameter optimalisation...')
tic;
options = optimset;
options.Display = 'final';
options.MaxIter = 100;
%[nlml] = nlml_I_FITC(hyp, sn, u, f, yf, 'VFE')
[hyp_sn nlml] = fminsearch(@(hyp) nlml_I_FITC(hyp, u, f, yf, 'VFE'),[hyp,sn],options);
toc
hyp = abs(hyp_sn(1:end-1));
sf  = hyp(1);
l   = hyp(2:end);
sn  = abs(hyp_sn(end));
%sn  = sn*2;
sn2 = sn^2;
%}