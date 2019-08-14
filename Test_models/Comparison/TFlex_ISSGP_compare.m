fig2pdf = 0;
pdf2ipe = 0;

%% Incremental Sparse Spectrum Gaussian Process I-SSGP
D = 100;             % Number of random features
n = 3;              % Input dimension
RAND  = randn(D,n); %
SIGMA  =  RAND.*(1./l);
sf    =  sf;
l   =  l;

%% No normalisation of data
mu_X  = [0,0,0];
sig_X = [1,1,1];
mu_Y  = 0;
sig_Y = 1;

%% Run simulation
m_eq = 0;
tic;
sim('TFlex_ISSGP_noHyp')
elap_time = toc;

%% Plot Results
Error = error(:)*pi/180;
FF_SSGP = FF_SSGP(:);
FF_RBD = FF_RBD(:);
controlOutput = controlOutput(:);
torqueError   = trainingTarget(:);
actualCurrent = actualCurrent(:);
setpointCurrent = setpointCurrent(:);
t     = [0:length(Error)-1]*ts;
ist  = 1000;
tOn1 = t_learn;
tOn2 = t_end;
t1 = [tOn1 tOn1];
t2 = [tOn2 tOn2];


fSize  = 20;
fig151 = figure(151),clf(151)
ylimits = [-0.00005 0.00005];
han(1,1) = subplot(2,1,1);
hold on
set(gca,'FontSize',fSize-3)
plot(t(ist:end),Error(ist:end))
ylimit(1) = min([Error(ist:end);ylimits(1)]);
ylimit(2) = max([Error(ist:end);ylimits(2)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
title(['Incremental-Sparse Spectrum GP ','(D=',num2str(D),')'],'Interpreter','Latex','FontSize',fSize)
%legend('\theta_1')
%ylim(ylimits)
ylabel('$e$ (rad)','Interpreter','Latex','FontSize',fSize)
hold off

han(2,1) = subplot(2,1,2);
hold on 
set(gca,'FontSize',fSize-3)
plot(t(ist:end),controlOutput(ist:end));
plot(t(ist:end),FF_SSGP(ist:end),'LineWidth',1.5);
ylimit(1) = min([controlOutput(ist:end);FF_SSGP(ist:end)]);
ylimit(2) = max([controlOutput(ist:end);FF_SSGP(ist:end)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
legend('$u_{FB}$','$u_{UD}$','Interpreter','Latex','FontSize',fSize)
ylabel('(mA)','Interpreter','Latex','FontSize',fSize)
xlabel('time (s)','Interpreter','Latex','FontSize',fSize)
hold off

%{
han(3,1) = subplot(2,1,3);
hold on 
plot(t(ist:end),FF_SSGP(ist:end))
ylimit(1) = min([FF_SSGP(ist:end)]);
ylimit(2) = max([FF_SSGP(ist:end)]);
plot(t1,ylimit,'--k')
plot(t2,ylimit,'--k')
%legend('FF')
ylabel('I-SSGP FF (mA)')
xlabel('time (s)')
hold off
%}
[fig151,han] = subplots(fig151,han,'gabSize',[0.09, 0.07])

%% Setpoint
q = squeeze(trainingInput(:,1,:));
%q = trainingInput';
%
fig150 = figure(150); clf(150);
ha(1,1) = subplot(4,1,1);
hold on
plot(t,q(1,:))
ylabel('(rad)')
hold off

ha(2,1) = subplot(4,1,2);
hold on
plot(t,q(2,:))
ylabel('(rad/s)')
hold off

ha(3,1) = subplot(4,1,3);
hold on
plot(t,q(3,:))
ylabel('(rad/s^2)')
hold off

ha(4,1) = subplot(4,1,4);
hold on
plot(t,FF_SSGP,'r')
ylabel('(N m)')
hold off

[fig150,ha] = subplots(fig150,ha)

%% Elapsed time
fprintf('\nDelay introduced by State Variable Filter: %i timesteps\n',svf_delay)

fprintf('\nElapsed time during simulation: %.3f s (D = %i) \n',[elap_time,D]);
fprintf("Time, using 'solve_chol_sfun' during simulation: %.3f s \n",t_end-t_learn);

%% Noise calculation
signal = torqueError(5/ts:end);
mu = mean(signal);

sn_measured = rms(signal-mu);
fprintf('\n')
fprintf('Noise (RMS): %f mA\n',sn_measured)

%% ERROR 
Error = error(:);
N = length(trainingTarget(:));
i_noISSGP = t_predict/ts;
i_ISSGP   = (100)/ts;
rmsErrorStationary = [0.621084,0.293680]*1e-3;
if N > i_ISSGP
    format shortEng
    fprintf('\n')
    fprintf('RMS error (10^-3 degree):\n')
    fprintf('Before I-SSGP: %f \n',rms(Error(1:i_noISSGP))*10^3)
    fprintf('After  I-SSGP: %f \n',rms(Error(i_ISSGP:end))*10^3)
    fprintf('Stationary   : %f  (at 3.3 degree)\n',rmsErrorStationary(1)*10^3)
    fprintf('Stationary   : %f  (at -3.3 degree)\n',rmsErrorStationary(2)*10^3)
    format
else
    fprintf('\nNo predictions made using I-SSGP... \n')
end

%% Save Figures
if(fig2pdf)
    saveas(fig222,fullfile(pwd,'Images','Hyperparameters.pdf'))
    saveas(fig150,fullfile(pwd,'Images','TrainingData.pdf'))
    saveas(fig151,fullfile(pwd,'Images','Error_FB_FF.pdf'))
end
%% PDF2IPE
if(pdf2ipe)
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end
