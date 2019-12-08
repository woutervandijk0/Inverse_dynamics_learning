function [C,C_d] = tunePID(crossOver,m_eq,ts)
alpha = 0.2;     % Phase lead
beta  = 2;       % Integral action

s = tf('s');
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
C = kp * (tau_z*s +1)*(tau_i*s + 1)/(tau_i*s*(tau_p*s+1));   % Continuous
C_d = c2d(C,ts,'tustin');                                 % Discrete
end