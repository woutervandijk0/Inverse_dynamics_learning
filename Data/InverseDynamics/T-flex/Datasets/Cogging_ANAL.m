%% Cogging data analysis - init
%close all;
%clear all;
%clc;
%enable or disable plot 1= true
plots =1;
%file name data
DatasetWM = 'CoggingADRCV100WM.DAT';
%% Options
Offset_begin = 20000;
Offset_end = 10000;

%state variable filter parameters
ts = 0.001;
Wv = 35*2*pi;
a0 = Wv^3;
a1 = 3*Wv^2;
a2 = 3*Wv;
%% load data with mass
matlab_data = SimulinkRealTime.utils.getFileScopeData(DatasetWM);
%matlab_data.data = matlab_data.data(Offset_begin:end-Offset_end,:);

% Import data
tlong = matlab_data.data(:,end)-ts;%-Offset_begin*ts;
u = matlab_data.data(:,3);
y = matlab_data.data(:,1)/180 *pi;
ysp = matlab_data.data(:,6)/180 *pi;
isp = matlab_data.data(:,2);
ia = matlab_data.data(:,3);
m = matlab_data.data(:,7);

%filter current noise.
Time = max(tlong)+ts;
Ytime = timeseries(y,tlong);
sim('State_estimation.slx',Time);
yfil = YVA.data(:,1);
yfil = yfil(Offset_begin:end-Offset_end,:);
vfil = YVA.data(:,2);
vfil = vfil(Offset_begin:end-Offset_end,:);
afil = YVA.data(:,3);
afil = afil(Offset_begin:end-Offset_end,:);
Ytime = timeseries(ia,tlong);
sim('State_estimation.slx',Time);
ifil = YVA.data(:,1);
ifil = ifil(Offset_begin:end-Offset_end,:);

v = vfil;
a = afil;


matlab_data.data = matlab_data.data(Offset_begin:end-Offset_end,:);

% Import data
tlong = matlab_data.data(:,end)-Offset_begin*ts;
u = matlab_data.data(:,3);
y = matlab_data.data(:,1)/180 *pi;
ysp = matlab_data.data(:,6)/180 *pi;
isp = matlab_data.data(:,2);
ia = matlab_data.data(:,3);
m = matlab_data.data(:,7);

d1 = designfilt('lowpassiir','FilterOrder',12, ...
    'HalfPowerFrequency',0.15,'DesignMethod','butter');
yfilfil = filtfilt(d1,y);
figure(99)
hold on
plot(y)
plot(yfil)
plot(yfilfil)
legend('org','SFF','Filtfilt')
d1 = designfilt('lowpassiir','FilterOrder',12, ...
    'HalfPowerFrequency',0.15,'DesignMethod','butter');
ifilfil = filtfilt(d1,ia);
figure(98)
hold on
plot(ia)
plot(ifil)
plot(ifilfil)
legend('org','SFF','Filtfilt')



% show dirty imported data
if plots ==1
    figure(1)
    subplot(3,2,1)
    plot(tlong,y,tlong,ysp,tlong,yfil);
    title('Positions')
    legend('Y_{meas} (deg)','Y_{sp} (deg)','Y_{filter} (deg)')
    xlabel('Time (s)')
    subplot(3,2,2)
    plot(tlong,y-ysp);
    title('Diff in Yset and Ymeas')
    legend('Error in position (deg)')
    xlabel('Time (s)')
    subplot(3,2,3)
    plot(tlong,v)
    title('Velocity')
    legend('Velocity (deg/s)')
    xlabel('Time (s)')
    subplot(3,2,4)
    plot(tlong,a)
    legend('Acceleration (deg/s^2)')
    title('Acceleration')
    xlabel('Time (s)')
    subplot(3,2,5)
    plot(y,ia,y,isp,yfil,ifil)
    title('Current')
    legend('I_{meas} (mA)','I_{set} (mA)','I_{filter} (mA)')
    xlabel('Degrees (deg)')
    subplot(3,2,6)
    plot(y,ia-isp,y,ifil-isp)
    title('Diff in Iset and Imeas')
    legend('I_{diff} (mA)','I_{diff} filtered')
    xlabel('Degrees (deg)')

    figure(2)
    plot(y,v)
    figure(3)
    plot(y,ifil-isp)
    yyaxis left
    plot(y(100:end),a(100:end))
    title('current difference sp and actual vs accel')
    legend('I_{diff} (mA)','Acceleration (deg/s^2)')
    figure(4)
    title('error SP-meas')
    plot(y,ysp-y)
    figure(5)
    hold on
    plot(yfil,ifil)
    xlabel('Position (rad)')
    ylabel('Current (mA)')
    figure(6)
    hold on
    plot(y,isp)
    xlabel('Position (rad)')
    ylabel('Current (mA)')
    grid on
    legend('1 (deg s^{-1})','3 (deg s^{-1})','10 (deg s^{-1})')

end

% %split data into movements
[Nispm]= splitdata(isp,m);
[Niam]  = splitdata(ia,m);
[Nifilm]= splitdata(ifilfil,m);
%Nifilfilm = splitdata(ifilfil,m)
[Nym]     = splitdata(y,m);
[Nyspm] = splitdata(ysp,m);
Nyfilm = splitdata(yfilfil,m);
[Nvam]     = splitdata(v,m);
[Nam]     = splitdata(a,m);



%% Biastest at different velocities
    figure(88)
    hold on
I_biasmean = zeros(1,3000);
p = 0;
for i = 21:4:length(Nam)
    [bfor,tfor] = resample(Nifilm{i}',Nyfilm{i}',2500,1,1);
    [back,tback] = resample(Nifilm{i+2}',Nyfilm{i+2}',2500,1,1);
    Asize = min(length(back),length(bfor));
    Ibias = bfor(1:Asize)-back(1:Asize);
    size(Ibias)
    I_biasmean = I_biasmean+[Ibias,zeros(1,length(I_biasmean)-Asize)];
    p = p+1;
end
plot(  tfor(1:Asize),I_biasmean(1:Asize)/p)
legend('1 (deg s^{-1})','3 (deg s^{-1})','10 (deg s^{-1})','25 (deg s^{-1})','50 (deg s^{-1})',...
    '100 (deg s^{-1})','200 (deg s^{-1})')
%title('Current bias at different velocities')    
xlabel('Position (rad)');
ylabel('Current (mA)');
grid on;

%% plot position setpoint, measured and error 
figure(10)
hold on
subplot(4,2,1)
hold on
for i = 1:4:length(Nam)
plot(ts:ts:(length(Nym{i})*ts),Nym{i})
plot(ts:ts:(length(Nyspm{i})*ts),Nyspm{i})
end
xlabel('Time (s)');
ylabel('Position (rad)');

subplot(4,2,2)
hold on
for i = 1:4:length(Nam)
plot(Nyspm{i},Nym{i}-Nyspm{i})
Emax(i) = max(abs(Nym{i}-Nyspm{i}));
hold on
end
xlabel('Position (rad)');
ylabel('Error (rad)');
max(Emax)
subplot(4,2,3)
hold on
for i = 2:4:length(Nam)
plot(ts:ts:(length(Nym{i})*ts),Nym{i})
plot(ts:ts:(length(Nyspm{i})*ts),Nyspm{i})
end
xlabel('Time (s)');
ylabel('Position (rad)');

subplot(4,2,4)
hold on
for i = 2:4:length(Nam)
plot(Nyspm{i},Nym{i}-Nyspm{i})
end
xlabel('Position (rad)');
ylabel('Error (rad)');

subplot(4,2,5)
hold on
for i = 3:4:length(Nam)
plot(ts:ts:(length(Nym{i})*ts),Nym{i})
plot(ts:ts:(length(Nyspm{i})*ts),Nyspm{i})
end
xlabel('Time (s)');
ylabel('Position (rad)');

subplot(4,2,6)
hold on
for i = 3:4:length(Nam)
plot(Nyspm{i},Nym{i}-Nyspm{i})
end
xlabel('Position (rad)');
ylabel('Error (rad)');

subplot(4,2,7)
hold on
for i = 4:4:length(Nam)-1
plot(ts:ts:(length(Nym{i})*ts),Nym{i})
plot(ts:ts:(length(Nyspm{i})*ts),Nyspm{i})
end
xlabel('Time (s)');
ylabel('Position (rad)');

subplot(4,2,8)
hold on
for i = 4:4:length(Nam)-1
plot(Nyspm{i},Nym{i}-Nyspm{i})
end
xlabel('Position (rad)');
ylabel('Error (rad)');

suptitle('Position and errors')
%% plot Velocity setpoint, measured and error 
figure(11)

subplot(4,2,1)
hold on
for i = 1:4:length(Nam)
plot(Nym{i})
plot(Nyspm{i})
end
xlabel('Time (s)');
ylabel('Position (rad)');

subplot(4,2,2)
hold on
for i = 5:4:length(Nam)
plot(Nym{i},Nvam{i})
end
xlabel('Position (rad)');
ylabel('Velocity (rad s^{-1})');

subplot(4,2,3)
hold on
for i = 2:4:length(Nam)
plot(Nym{i})
plot(Nyspm{i})
end
xlabel('Time (s)');
ylabel('Position (rad)');

subplot(4,2,4)
hold on
for i = 2:4:length(Nam)
plot(Nym{i},Nvam{i})
end
xlabel('Position (rad)');
ylabel('Velocity (rad s^{-1})');

subplot(4,2,5)
hold on
for i = 3:4:length(Nam)
plot(Nym{i})
plot(Nyspm{i})
end
xlabel('Time (s)');
ylabel('Position (rad)');

subplot(4,2,6)
hold on
for i = 3:4:length(Nam)
plot(Nym{i},Nvam{i})
end
xlabel('Position (rad)');
ylabel('Velocity (rad s^{-1})');

subplot(4,2,7)
hold on
for i = 4:4:length(Nam)-1
plot(Nym{i})
plot(Nyspm{i})
end
xlabel('Time (s)');
ylabel('Position (rad)');

subplot(4,2,8)
hold on
for i = 4:4:length(Nam)-1
plot(Nym{i},Nvam{i})
end
xlabel('Position (rad)');
ylabel('Velocity (rad s^{-1})');
%% plot Acceleration setpoint, measured and error
figure(13)

subplot(4,2,1)
hold on
for i = 1:4:length(Nam)
plot(Nym{i})
plot(Nyspm{i})
end
xlabel('Time (s)');
ylabel('Position (rad)');

subplot(4,2,2)
hold on
for i = 21:4:length(Nam)
plot(Nym{i},Nam{i})
end
xlabel('Position (rad)');
ylabel('Acceleration (rad s^{-2})');

subplot(4,2,3)
hold on
for i = 2:4:length(Nam)
plot(Nym{i})
plot(Nyspm{i})
end
xlabel('Time (s)');
ylabel('Position (rad)');

subplot(4,2,4)
hold on
for i = 2:4:length(Nam)
plot(Nym{i},Nam{i})
end
xlabel('Position (rad)');
ylabel('Acceleration (rad s^{-2})');


subplot(4,2,5)
hold on
for i = 3:4:length(Nam)
plot(Nym{i})
plot(Nyspm{i})
end
xlabel('Time (s)');
ylabel('Position (rad)');

subplot(4,2,6)
hold on
for i = 3:4:length(Nam)
plot(Nym{i},Nam{i})
end
xlabel('Position (rad)');
ylabel('Acceleration (rad s^{-2})');

subplot(4,2,7)
hold on
for i = 4:4:length(Nam)-1
plot(Nym{i})
plot(Nyspm{i})
end
xlabel('Time (s)');
ylabel('Position (rad)');

subplot(4,2,8)
hold on
for i = 4:4:length(Nam)-1
plot(Nym{i},Nam{i})
end
xlabel('Position (rad)');
ylabel('Acceleration (rad s^{-2})');


%% 
% %% Plots - unfiltered
% if plots ==1
% figure(21)
% hold on
% plot(NymP,NispmP, WymP,WispmP, NymN,NispmN, WymN,WispmN)
% plot(mean(NymP,2),mean(NispmP,2),mean(NymN,2),mean(NispmN,2),mean(WymP,2),mean(WispmP,2),mean(WymN,2),mean(WispmN,2))
% legend('no mass pos', 'no mass neg', 'with mass pos', 'with mass neg' )
% title('Plot mean data all movements')
% 
% figure(22)
% hold on
% plot(NymP,NiamP,WymP,WiamP)
% plot(mean(NymP,2),mean(NiamP,2),mean(WymP,2),mean(WiamP,2))
% title('Plot mean data all movements mean between pos neg')
% 
% flipN = fliplr( mean(NiamN,2)' )';
% figure(24)
% plot(mean(NymP,2),mean(NiamP,2),mean(NymN,2),mean(NiamN,2),mean(NymP,2),(mean(NiamP,2)-flipN))
% legend('NiamP', 'NiamN', 'diff')
% title('difference in pos neg of NM')
% 
% flipW = fliplr( mean(WiamN,2)' )';
% figure(25)
% plot(mean(WymP,2),mean(WiamP,2),mean(WymN,2),mean(WiamN,2),mean(WymP,2),(mean(WiamP,2)-flipW))
% legend('NiamP', 'NiamN', 'diff')
% title('difference in pos neg of WM')
% 
% figure(26)
% plot(mean(NymP,2),(mean(NiamP,2)-flipN),mean(WymP,2),(mean(WiamP,2)-flipW))
% title('unexplain able offset')
% end
% 
% %% Plots - filtered
% if plots ==1
% figure(31)
% hold on
% plot(NymP,NispmP, WymP,WispmP, NymN,NispmN, WymN,WispmN)
% plot(mean(NymP,2),mean(NispmP,2),mean(NymN,2),mean(NispmN,2),mean(WymP,2),mean(WispmP,2),mean(WymN,2),mean(WispmN,2))
% legend('no mass pos', 'no mass neg', 'with mass pos', 'with mass neg' )
% title('Plot mean data all movements')
% 
% figure(32)
% hold on
% plot(NyfP,NifmP,WyfP,WifmP)
% plot(mean(NyfP,2),mean(NifmP,2),mean(WyfP,2),mean(WifmP,2))
% title('Plot mean filtered data all movements mean between pos neg')
% 
% flipN = fliplr( mean(NifmN,2)' )';
% figure(34)
% plot(mean(NyfP,2),mean(NifmP,2),mean(NyfN,2),mean(NifmN,2),mean(NyfP,2),(mean(NifmP,2)-flipN))
% legend('NiamP', 'NiamN', 'diff')
% title('difference in pos neg of NM')
% 
% flipW = fliplr( mean(WifmN,2)' )';
% figure(35)
% plot(mean(WyfP,2),mean(WifmP,2),mean(WyfN,2),mean(WifmN,2),mean(WyfP,2),(mean(WifmP,2)-flipW))
% legend('NiamP', 'NiamN', 'diff')
% title('difference in pos neg of WM')
% 
% figure(36)
% plot(mean(NyfP,2),(mean(NifmP,2)-flipN),mean(WyfP,2),(mean(WifmP,2)-flipW))
% title('unexplain able offset')
% legend('Without mass','With mass')
% end
% 
% %% Gravity estimations - estmate K-factor
% %get gravity data - it is advised to use a big displacement
% GravP = -mean(NiamP,2)+mean(WiamP,2);
% GravN = (-mean(NiamN,2)+mean(WiamN,2));
% GravM = (GravP + flip(GravN))/2;
% PosP = mean(NymP,2);        %(deg)
% PosN = mean(NymN,2);        %(deg)
% freq = 2*pi/360;            %frequency of gravity is 1.(rad/s)
% Mass = 1.465;               %kilogram (Kg)
% L_arm =0.187;               %length of arm to COM additional weight (m)
% G = 9.8127;                 %G in twente
% 
% [paramsiP,yi_estP,yi_residP,err_rmsiP] = sinefit(GravP,mean(NymP,2),2*pi/360);
% [paramsiN,yi_estN,yi_residN,err_rmsiN] = sinefit(GravN,mean(NymN,2),2*pi/360);
% [paramsiM,yi_estM,yi_residM,err_rmsiM] = sinefit(GravM,mean(NymP,2),2*pi/360);
% 
% figure(23)
% hold on
% plot(mean(NymP,2),GravP,mean(NymN,2),GravN,mean(NymP,2),yi_estP,mean(NymN,2),yi_estN,mean(NymP,2),yi_estM);
% %plot(Gravity)
% legend('Mass positive', 'Mass negative', 'calculated1','calculated2','calculated3')
% title('Gravity')
% xlabel('Degrees(deg)')
% ylabel('I (mA)')
% 
% %use the amplitude of mean estimate.
% Ampl = paramsiM(2)/1000; %from mA to A
% Kt = L_arm*G*Mass/Ampl
% 
% %% Gravity estimations filter- estmate K-factor
% %get gravity data - it is advised to use a big displacement
% GravP = -mean(NifmP,2)+mean(WifmP,2);
% GravN = (-mean(NifmN,2)+mean(WifmN,2));
% GravM = (GravP + flip(GravN))/2;
% PosP = mean(NyfP,2);        %(deg)
% PosN = mean(NyfN,2);        %(deg)
% freq = 2*pi/360;            %frequency of gravity is 1.(rad/s)
% Mass = 1.465;               %kilogram (Kg)
% L_arm =0.187;               %length of arm to COM additional weight (m)
% G = 9.8127;                 %G in twente
% 
% [paramsiP,yi_estP,yi_residP,err_rmsiP] = sinefit(GravP,mean(NyfP,2),2*pi/360);
% [paramsiN,yi_estN,yi_residN,err_rmsiN] = sinefit(GravN,mean(NyfN,2),2*pi/360);
% [paramsiM,yi_estM,yi_residM,err_rmsiM] = sinefit(GravM,mean(NyfP,2),2*pi/360);
% 
% figure(23)
% hold on
% plot(mean(NyfP,2),GravP,mean(NyfN,2),GravN,mean(NyfP,2),GravM,mean(NyfP,2),yi_estP,mean(NyfN,2),yi_estN,mean(NyfP,2),yi_estM);
% %plot(Gravity)
% legend('Mass positive', 'Mass negative','Mass mean', 'calculated1','calculated2','calculated3')
% title('Gravity')
% xlabel('Degrees(deg)')
% ylabel('I (mA)')
% 
% %use the amplitude of mean estimate.
% Ampl = paramsiM(2)/1000; %from mA to A
% Kt = L_arm*G*Mass/Ampl
% %% compare dataset WM - grav to dataset NM
% %get gravity data - it is advised to use a big displacement
% GravNM = mean(WiamP,2);
% PosP = mean(NymP,2);        %(deg)
% freq = 2*pi/360;            %frequency of gravity is 1.(rad/s)
% 
% 
% [paramsiP,yi_estP,yi_residP,err_rmsiP] = sinefit(GravNM,mean(NymP,2),2*pi/360);
% 
% figure(24)
% hold on
% plot(PosP,GravNM,PosP,yi_estP);
% %plot(Gravity)
% legend('Mass positive', 'Mass negative', 'calculated1','calculated2','calculated3')
% title('Gravity')
% xlabel('Degrees(deg)')
% ylabel('I (mA)')
% 
% %% compare dataset WM - grav to dataset NM
% %get gravity data - it is advised to use a big displacement
% GravNM = mean(NifmP,2);
% PosP = mean(WyfP,2);        %(deg)
% freq = 2*pi/360;            %frequency of gravity is 1.(rad/s)
% 
% 
% [paramsiP,yi_estP,yi_residP,err_rmsiP,r , test] = sinefit(GravNM,PosP,freq,0.0001);
% 
% figure(24)
% hold on
% plot(PosP,GravNM,PosP,yi_estP);
% legend('Mass positive','calculated1','calculated2','calculated3')
% title('Gravity')
% xlabel('Degrees(deg)')
% ylabel('I (mA)')
% figure
% plot(PosP,GravNM-yi_estP)
% %% estimate the springstiffness
% a=1
% 
%  %% calculate torques as a function of deg
% % theta = [-25:0.01:25];
% % M = 1.465;  % kg mass
% % R = 0.1926;  % M length of the arm for the COM
% % G = 9.8127;% G in twente
% % Kt = 5.57/1000;
% % Mg = M*G*R*cosd(theta+10.2);
% % % estimate the required current
% % Ig = Mg / Kt; 
% % %%2x buttergly hinges
% % %from simulation for 1 hinge the values 2 nm for 0.4 rad displacement has been found
% % deg = 0.4/pi*180; %change rad to deg
% % Ta = 2/deg;
% % Tspring = Ta *theta;
% % Ispring = Tspring/Kt;
% % figure(5)
% % plot(theta,Mg,theta,Tspring,theta,Mg+Tspring)
% % legend('Mg', 'Tspring', 'Both')
% % figure(6)
% % plot(theta,Ig,theta,Ispring,theta,Ig+Ispring)
% % legend('Ig', 'Ispring', 'Both')
% % 
% % %%
% % p = polyfit(mean(NymP,2),mean(NiamP,2),2);
% % p2 = polyfit(mean(WymP,2),mean(WiamP,2),2);
% % f1 = polyval(p,mean(NymP,2));
% % f2 = polyval(p2,mean(NymP,2));
% % figure
% % plot(mean(NymP,2),mean(NiamP,2))
% % hold on
% % plot(mean(WymP,2),mean(WiamP,2))
% % plot(mean(NymP,2),f1)
% % plot(mean(NymP,2),f2)
% % %plot(x1,f1,'r--')
% % legend('y','y1','f1')
% % 
% % figure(87)
% % hold on
% % plot(mean(NymP,2),mean(NiamP,2)-f1)
% % plot(mean(WymP,2),mean(WiamP,2)-f2)
% % xlabel('Degrees(deg)')
% % ylabel('I(mA)')
% % title('Cogging')
% % %change current to torque
% % Cogging = (mean(NiamP,2)-f1)*Kt
% % figure
% % plot(mean(NymP,2),Cogging)

