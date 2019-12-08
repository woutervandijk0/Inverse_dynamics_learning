%% Sample time
%Define ts if not existing
if ~exist('ts')
    ts = 1/1000;    %[s] Sample time
end

%% Reference generator
Reference.seed  = 35;   % Seed for random integer generator
Reference.ts    = 2.5;                % Sample time of setpoint generator
% Skewsine Reference Generator
Reference.skewSine.tm = 2 ;     % [s] Settle time

%Transient reference generator
Reference.transient.r = 2.5e2;
Reference.transient.h = 10*ts;

%% TFlex plant
s = tf('s');
%P = 1/(0.2*s^2 + 0.74*s + 15.46)
P = 1/(0.15*s^2 + 0.5*s + 16.12)
[Pnum,Pden] = tfdata(P,'v');

%Write to struct
Plant.P    = P;
Plant.Pnum = Pnum;
Plant.Pden = Pden;

%% PID
%Motor settings
I_limit = 500;    % [mA]   Current limit
gainMotor = 5.56;  % [Nm/A] Motor constant

crossOver = 15*2*pi;     %[rad/s]
m_eq  = 0.15;     % Equivalent mass
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
P_d  = c2d(Plant.P,ts);

% Open loop stability
%{
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
%}

%Write to struct
PID.ts    = ts;
PID.crossOver = crossOver;     %[rad/s]
PID.m_eq  = m_eq;     % Equivalent mass
PID.alpha = alpha;    % Phase lead
PID.beta  = beta;     % Integral action

PID.kp    = kp;
PID.tau_z = tau_z;
PID.tau_i = tau_i;
PID.tau_p = tau_p;

PID.Kp = Kp;
PID.Ki = Ki;
PID.Kd = Kd;

PID.LPnum = LPnum;
PID.LPden = LPden;

%% state variable filter (2nd Order)
omega_n = 50*2*pi;  %[rad/s] Natural frequency
% Coefficients
a0 = omega_n^3;
a1 = 3*omega_n^2;
a2 = 3*omega_n;

%Transfer function
%SVF   = 1/(s^3 + a2*s^2 + a1*s + a0);   % Continuous

%Write to struct
SVF.natFreq = omega_n;
SVF.a0 = a0;
SVF.a1 = a1;
SVF.a2 = a2;

%% RBD Feed Forward
m_est = 0.2;
d     = 0.74;
k_est = 15.46;

%Write to struct
FF_RBD.m_est  = m_est;
FF_RBD.d     = d;
FF_RBD.k_est = k_est;

%% Cogging 
angle = linspace(-0.4189,0.4189,500);   %[rad]
f = [4*pi, 4*pi*8];     % Frequencies
p = [pi/2.5, pi/2];     % Phase
a = [20, 3]*0.9;        % Amplitude

%Resultant cogging signal 
angle = [angle',angle'];
c     = sum( a.*sin(angle.*f + p),2);

% Plot cogging signal
%{
figure(101),clf(101)
hold on
plot(angle,c)
ylim([-40 40])
%}

%Write to struct
Cogging.amplitude = a';
Cogging.phase     = p';
Cogging.frequency = f';

%% Hysteresis (reset integrator)
Hysteresis.gain  = 5;
Hysteresis.p0    = 3.0367;

%% Gravity
l = 0.187/2;        %[m]     Length
m = 1.46;           %[kg]    Mass
g = 9.81;           %[m/s^2] Gravitational acceleration
phase = -pi/20;     %[rad]   Phase
gainMotor = 5.56;   %[Nm/A]  Motor constant

rot = linspace(-0.1745*pi,0.1745*pi,501);
F_g = l*m*g*sin(rot/(2*pi)+phase)./gainMotor*1000;

%Write to struct
gravity.l = l;
gravity.m = m;
gravity.g = g;
gravity.motorGain = gainMotor;
gravity.constant = 1000*m*g*l/gainMotor;
gravity.phase = phase;

%Plot gravity
%{
figure(1111)
plot(rot,F_g)
%}

%% Clear workspace
clear l m g phase gainMotor F_g rot
clear d m_est k_est
clear P Pnum Pden
clear a p f c index angle
clear m_est P_est P_est_d P_estnum P_estden
clear a0 a1 a2 omega_n crossover mag phase wout svf_delay 
clear crossover m_eq alpha beta kp tau_z tau_i tau_p Kp Ki Kd LPnum LPden P_d Cpid Cpid_d LPnum LPden LP LP_d

