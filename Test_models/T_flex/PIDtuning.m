%%PID
s = tf('s');
P= 1/(0.2*s^2 + 0.2292*s+11.36); % model of the plant
P= 1/(0.2*s^2 + 0.001*s+11.36); % model of 
P= 1/(0.2*s^2 + 0.74*s+11.46); % model of the plantthe plant
[Pnum,Pden] = tfdata(P,'v');

Wc = 35*2*pi;%45*2*pi;
A = 0.1;
B = 10;
M = 0.20;

Tz = sqrt(1/A)/Wc;
Ti = B*Tz;
Tp = 1/(sqrt(1/A)*Wc);
Kp = M*Wc^2/sqrt(1/A);

Cpid = Kp * (Tz*s +1)*(Ti*s + 1)/(Ti*s*(Tp*s+1));

figure(1)
    subplot(1,3,1)
    bode(Cpid,P)
    grid on
    subplot(1,3,2)
    nichols(Cpid,P)
    grid on
    subplot(1,3,3)
    nyquist(Cpid,P)
    grid on
    
 Loop = loopsens(P,Cpid);
 
 figure(2)
    subplot(1,3,1)
    bode(Loop.Si,Loop.Ti,P*Loop.Si)
    legend('Sentivity function','Compl sens function','noise sens function')
    grid on
    subplot(1,3,2)
    nichols(Loop.Si,Loop.Ti,P*Loop.Si)
    grid on
    subplot(1,3,3)
    nyquist(Loop.Si,Loop.Ti,P*Loop.Si)
    grid on
PID_bandw=bandwidth(Loop.Ti)
%discrete version
ts = 1/1000;
Pd = c2d(P,ts, 'zoh');
Cpidd = c2d(Cpid,ts, 'tustin');
figure(27)
    bode(Cpid,Cpidd)
    grid on
    hold on
Loopd = loopsens(Pd,Cpidd);
 figure(3)
    subplot(1,3,1)
    bode(Loopd.Si,Loopd.Ti,Pd*Loopd.Si)
    legend('Sentivity function','Compl sens function','noise sens function')
    grid on
    subplot(1,3,2)
    nichols(Loopd.Si,Loopd.Ti,Pd*Loopd.Si)
    grid on
    subplot(1,3,3)
    nyquist(Loopd.Si,Loopd.Ti,Pd*Loopd.Si)
    grid on
PID_bandwd=bandwidth(Loopd.Ti)
 figure(19)
     bode(Loopd.Si,Loopd.Ti,Pd*Loopd.Si)
    legend('Sentivity function','Compl sens function','noise sens function')
    grid on
    hold on
%{
%% V3 - PID+
s = tf('s');
P= 1/(0.2*s^2 + 0.2292*s+11.36)*exp(-0.003*s); % model of the plant
[Pnum,Pden] = tfdata(P,'v');

Wc = 25*2*pi;
A = 0.55;
B = 10;
M = 0.20;

%PID+ parameters
Cn = 0.3;
Cd = 0.3;



Tz = sqrt(1/A)/Wc;
Ti = Tz;
Tp = 1/(sqrt(1/A)*Wc);
Kp = M*Wc^2/sqrt(1/A);

Cpid = Kp * (Tz*s +1)*(Ti*s + 1)/(Ti*s*(Tp*s+1));
Cpidd= Kp * (s^2*Ti^2 +2*Cn*Ti*s+1)/(s*Ti*(s^2 *Tp^2 + 2*Cd*Tp*s +1)) 

figure(4)
    subplot(1,3,1)
    bode(Cpidd,P)
    grid on
    subplot(1,3,2)
    nichols(Cpid,P)
    grid on
    
 Loop = loopsens(P,Cpidd);
 
 figure(5)
    subplot(1,3,1)
    bode(Loop.Si,Loop.Ti,P*Loop.Si)
    legend('Sentivity function','Compl sens function','noise sens function')
    grid on
    subplot(1,3,2)
    nichols(Loop.Si,Loop.Ti,P*Loop.Si)
    grid on
    subplot(1,3,3)
    nyquist(Loop.Si,Loop.Ti,P*Loop.Si)
    grid on
PIDD_bandw=bandwidth(Loop.Ti)
%discrete version
ts = 1/1000;
Pd = c2d(P,ts, 'zoh');
Cpiddd = c2d(Cpidd,ts, 'tustin');
[Cnum,Cden] = tfdata(Cpidd,'v');
Loopd = loopsens(Pd,Cpiddd);
 figure(6)
    subplot(1,3,1)
    bode(Loopd.Si,Loopd.Ti,Pd*Loopd.Si)
    legend('Sentivity function','Compl sens function','noise sens function')
    grid on
    subplot(1,3,2)
    nichols(Loopd.Si,Loopd.Ti,Pd*Loopd.Si)
    grid on
    subplot(1,3,3)
    nyquist(Loopd.Si,Loopd.Ti,Pd*Loopd.Si)
    grid on
PIDD_bandwd=bandwidth(Loopd.Ti)
    %}