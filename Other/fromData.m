%{
clc, clear all;
ts = 1/1000;
sysdata = SimulinkRealTime.utils.getFileScopeData('SYSOUT.DAT');

AngleDeg   = sysdata.data(:,1);
ActCurrent = sysdata.data(:,2);
ReqCurrent = sysdata.data(:,3);
TrajSystem = sysdata.data(:,4);

%% state variable filter (2nd Order)
s = tf('s');

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
clear crossover mag phase wout SVF_d SVF s omega_n 

%% Run angle through state variable filter
t = [0:length(ActCurrent)-1]*ts;
angle.time = t';
angle.signals.values = AngleDeg;
angle.signals.dimensions = [1];

current.time = t';
%current.signals.values = ReqCurrent;
current.signals.values = ActCurrent;
current.signals.dimensions = [1];

sim('SVF_fromWorkspace')
%close_system;
%%
y       = states.y.Data;
y_dot   = states.y_dot.Data;
y_ddot  = states.y_ddot.Data;

xTrain = [y,y_dot,y_ddot];
yTrain = ReqCurrent.Data;
%yTrain = ActCurrent;

tStart = 2;
iStart = tStart/ts;

%xTrain = xTrain(iStart-svf_delay:(end-svf_delay),:);
xTrain = xTrain(iStart:end,:);
yTrain = yTrain(iStart:end,:);
t      = [0:length(xTrain)-1]*ts

%{
fSize = 13;
fig151 = figure(151);,clf(fig151);
han151(1,1) = subplot(4,1,1)
plot(t,xTrain(:,1))
ylabel('$(deg)$','Interpreter','Latex','FontSize',fSize)
title('Multisine','Interpreter','Latex','FontSize',fSize)

han151(2,1) = subplot(4,1,2)
plot(t,xTrain(:,2))
ylabel('$(deg/s)$','Interpreter','Latex','FontSize',fSize)

han151(3,1) = subplot(4,1,3)
plot(t,xTrain(:,3))
ylabel('$(deg/s^2)$','Interpreter','Latex','FontSize',fSize)

han151(4,1) = subplot(4,1,4)
plot(t,yTrain)
ylabel('$(mA)$','Interpreter','Latex','FontSize',fSize)
xlabel('time (s)','Interpreter','Latex','FontSize',fSize)

[fig151,han151e] = subplots(fig151,han151);

fig1 = figure(1);
selectData('dataset','TFlexADRC_RN20.mat','figNum',1);


fig2pdf = 1;
pdf2ipe = 1;
%% Save Figures
if(fig2pdf)
    saveas(fig151,fullfile(pwd,'Images','TFlexMultisine.pdf'));
    saveas(fig1,fullfile(pwd,'Images','TFlexADRC_RN20.pdf'));
end

%% PDF2IPE
if(pdf2ipe)
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''});
end
%}
%%
xTrain = xTrain';
yTrain = yTrain';
%}
%% state variable filter (2nd Order)
s = tf('s');

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
clear crossover mag phase wout SVF_d SVF s omega_n 

%%
ts = 0.001;
AngleDeg = xTrain(1,:)';

t = [0:length(AngleDeg)-1]*ts;
angle.time = t';
angle.signals.values = AngleDeg;
angle.signals.dimensions = [1];

sim('SVF_fromWorkspace')

y       = states.y.Data;
y_dot   = states.y_dot.Data;
y_ddot  = states.y_ddot.Data;