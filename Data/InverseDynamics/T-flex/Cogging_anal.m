%% Cogging data analysis
%enable or disable plot 1= true
plots =0;
%close all
% load data no mass
matlab_data = SimulinkRealTime.utils.getFileScopeData('cogWMPCFR.DAT');
matlab_data.data = matlab_data.data(20000:end-1000,:);

tlong = matlab_data.data(:,end);
% Import data

%tlong = tlong(find((tlong<33)));
%indi = find(tlong>20);
%tlong = tlong(indi);
indi = 1:length(tlong);
u = matlab_data.data(indi,3);
y = matlab_data.data(indi,1);
ysp = matlab_data.data(indi,7);
v = matlab_data.data(indi,5);
a = matlab_data.data(indi,6);
isp = matlab_data.data(indi,2);
ia = matlab_data.data(indi,3);
m = matlab_data.data(indi,8);
%}
%{
indi = 1:length(tlong);
u = matlab_data.data(indi,3);
y = matlab_data.data(indi,1);
ysp = matlab_data.data(indi,6);
v = matlab_data.data(indi,5);
a = matlab_data.data(indi,6);
isp = matlab_data.data(indi,2);
n = matlab_data.data(indi,5);
ia = matlab_data.data(indi,3);
%m = matlab_data.data(indi,8);

%}

%show dirty imported data
if plots ==1
    figure(1)
    subplot(3,2,1)
    plot(tlong,y,tlong,ysp);
    title('Positions')
    legend('Y_{meas} [deg]','Y_{sp} [deg]')
    xlabel('Time [s]')
    subplot(3,2,2)
    plot(tlong,y-ysp);
    title('Diff in Yset and Ymeas')
    legend('Error in position [deg]')
    xlabel('Time [s]')
    subplot(3,2,3)
    plot(tlong,v)
    title('Velocity')
    legend('Velocity [deg/s]')
    xlabel('Time [s]')
    subplot(3,2,4)
    plot(tlong,a)
    legend('Acceleration [deg/s^2]')
    title('Acceleration')
    xlabel('Time [s]')
    subplot(3,2,5)
    plot(y,ia,y,isp)
    title('Current')
    legend('I_{meas} [mA]','I_{set} [mA]')
    xlabel('Degrees [deg]')
    subplot(3,2,6)
    plot(y,ia-isp)
    title('Diff in Iset and Imeas')
    legend('I_{diff} [mA]')
    xlabel('Degrees [deg]')

    figure(2)
    plot(y,v)
    figure(3)
    plot(y,ia-isp,y,a)
    figure(4)
    plot(y,y-ysp)
end

figure
vsp = diff(ysp);
vsp(2368:35334:end) = -3e-3;
vsp(21035:35334:end) = -3e-3;
vsp(20035:35334:end) = 3e-3;
vsp = [vsp(1);vsp];
plot(vsp)

figure
asp = diff(vsp);
asp = [asp(1);asp];
plot(asp)


%{
%split data into movements
[NispmP, NispmN]= splitdata(isp,m);
[NiamP, NiamN]  = splitdata(ia,m);
[NymP,NymN]     = splitdata(y,m);
[NyspmP,NyspmN] = splitdata(ysp,m);
[NvmP,NvmN]     = splitdata(v,m);
[NamP,NamN]     = splitdata(a,m);
t = [0:0.001:(length(find(m==1))-1)/1000]';

%% load data with mass
matlab_data = SimulinkRealTime.utils.getFileScopeData('H2cog25V3WM.DAT');
matlab_data.data = matlab_data.data(6000:end,:);

% Import data
tlong = matlab_data.data(:,end);
u = matlab_data.data(:,3);
y = matlab_data.data(:,1);
ysp = matlab_data.data(:,7);
v = matlab_data.data(:,5);
a = matlab_data.data(:,6);
isp = matlab_data.data(:,2);
ia = matlab_data.data(:,3);
m = matlab_data.data(:,8);

%show dirty imported data
if plots ==1
figure(12)
subplot(3,2,1)
plot(tlong,y,tlong,ysp)
title('Positions')
legend('Y_{meas} [deg]','Y_{sp} [deg]')
xlabel('Time [s]')
subplot(3,2,2)
plot(tlong,y-ysp)
title('Diff in Yset and Ymeas')
legend('Error in position [deg]')
xlabel('Time [s]')
subplot(3,2,3)
plot(tlong,v)
title('Velocity')
legend('Velocity [deg/s]')
xlabel('Time [s]')
subplot(3,2,4)
plot(tlong,a)
legend('Acceleration [deg/s^2]')
title('Acceleration')
xlabel('Time [s]')
subplot(3,2,5)
plot(y,ia,y,isp)
title('Current')
legend('I_{meas} [mA]','I_{set} [mA]')
xlabel('Degrees [deg]')
subplot(3,2,6)
plot(y,ia-isp)
title('Diff in Iset and Imeas')
legend('I_{diff} [mA]')
xlabel('Degrees [deg]')

figure(2)
plot(y,v)
figure(3)
plot(y,ia-isp,y,a)
figure(4)
plot(y,y-ysp)
end

%split data into movements
[WispmP, WispmN]= splitdata(isp,m);
[WiamP, WiamN]  = splitdata(ia,m);
[WymP,WymN]     = splitdata(y,m);
[WyspmP,WyspmN] = splitdata(ysp,m);
[WvmP,WvmN]     = splitdata(v,m);
[WamP,WamN]     = splitdata(a,m);
t = [0:0.001:(length(find(m==1))-1)/1000]';

if plots ==1
figure(21)
hold on
plot(NymP,NispmP, WymP,WispmP, NymN,NispmN, WymN,WispmN)
plot(mean(NymP,2),mean(NispmP,2),mean(NymN,2),mean(NispmN,2),mean(WymP,2),mean(WispmP,2),mean(WymN,2),mean(WispmN,2))
legend('no mass pos', 'no mass neg', 'with mass pos', 'with mass neg' )

figure(22)
hold on
plot(NymP,NiamP,WymP,WiamP)
plot(mean(NymP,2),mean(NiamP,2),mean(WymP,2),mean(WiamP,2))

end
%}