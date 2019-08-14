%% Sample time
%Define ts if not existing
if ~exist('ts')
    ts = 1/1000;    %[s] Sample time
end

%% Reference generator
Reference.seed  = 35;   % Seed for random integer generator
Reference.ts    = 2;                % Sample time of setpoint generator
% Skewsine Reference Generator
Reference.skewSine.tm    = 1.0;     % [s] Settle time

%Transient reference generator
Reference.transient.r = 1e3;
Reference.transient.h = 5*ts;

%% TFlex plant
s = tf('s');
P = 1/(0.2*s^2 + 0.74*s + 11.46)       %Tflex
[Pnum,Pden] = tfdata(P,'v');

%Write to struct
Plant.P    = P;
Plant.Pnum = Pnum;
Plant.Pden = Pden;

%% PID
%Motor settings
I_limit = 2000;    % [mA]   Current limit
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
P_d  = c2d(Plant.P,ts);

%{
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
omega_n = 100*2*pi;  %[rad/s] Natural frequency
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
clear SVF SVF_d

%Write to struct
SVF.natFreq = omega_n;
SVF.a0 = a0;
SVF.a1 = a1;
SVF.a2 = a2;
SVF.delay = svf_delay;

%% Smith Predictor && Feed Forward
m_est = 0.2;
%Estimated plant
P_est   = 1/(m_est*s^2);        % Continuous
P_est_d = c2d(P_est,ts);        % Discrete
[P_estnum,P_estden] = tfdata(P_est_d,'v');

%Write to struct
Smith.P_estnum = P_estnum;
Smith.P_estden = P_estden;

%% Cogging 
angle = linspace(-23,23,500);
f = [10, 5, 20, 2.5, 1.25];  % Frequencies
p = [0, 0, -5, 0, 2];        % Phase delay
a = [40, -20, 30, 2, 0.1];   % Amplitude (relative)
c    = sum( a'.*sin(((angle+p')*2*pi)./f'));
[maxValue,index] = max(c);
c    = a'.*sin(((angle(index)+p')*2*pi)./f');
a = a./maxValue;              % Normalized amplitudes 

%Write to struct
Cogging.amplitude = a';
Cogging.phase     = p';
Cogging.frequency = f';


clear P Pnum Pden
clear a p f c maxValue index angle
clear m_est P_est P_est_d P_estnum P_estden
clear a0 a1 a2 omega_n crossover mag phase wout svf_delay 
clear crossover m_eq alpha beta kp tau_z tau_i tau_p Kp Ki Kd LPnum LPden P_d Cpid Cpid_d LPnum LPden LP LP_d
