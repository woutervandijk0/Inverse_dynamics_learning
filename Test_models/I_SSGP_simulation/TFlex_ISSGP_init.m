%clc, clear all, %close all
fig2pdf = 0;        % Safe figures [yes/no]
pdf2ipe = 0;        % pdf to ipe   [yes/no]

%% Time settings
ts          = 1/1000;     %[s] Sample time
t_end       = 180;        %[s] Total simulation time
t_still     = 0;          %[s] Standstill time at beginning
t_hypUpdate = [t_end+1 t_end+2];    %[s] [start stop] hyperparameter optimization
t_learn     = 1;          %[s] Start time updating posterior
t_predict   = 41;         %[s] Make predictions

%% Initialize Controller & Plant settings
Tflex_Controller_init

%% Incremental Sparse Spectrum Gaussian Process I-SSGP
D = 21;             % Number of random features
n = 3;              % Training input dimension
RAND  = randn(D,n); % Pre-define random matrix

%% Hyperparameters
% Optimized Spectral points
%{
RAND = [-0.0443   -0.8255   -1.2712
    0.3405    0.4174   -1.1195
   -0.6384    0.4234    1.9109
    0.5158    1.5528   -0.2960
    0.8974    0.9502   -0.8139
   -1.4162    0.1306    0.2286
   -1.0696    1.6054   -1.6286
    0.9263    2.4743   -0.4250
   -0.5317    0.7552    0.3237
   -0.5051    1.3948    2.0170
   -0.0128   -2.5390    0.6301
    1.1631    0.9555    0.6321
   -1.3351   -0.1830    0.2767
    0.5935   -0.3138    1.0673
    1.2490    0.4955   -1.3632
   -0.0701   -0.9748    0.2229
   -1.0386   -2.3217   -1.7113
   -1.0611   -1.7548    0.4485
    1.0126   -0.8270   -1.1659
    0.3996    0.4874    0.0561
   -0.0427   -0.2273    0.2607];
%}

% Hyperparameters (Initial)
l = ones(1,n).*0.1; % Characteristic length scales
sf  = 1;            % Signal variance

% Hyperparameters (GOOD)
sf = 101.81 
sn = 1.4493 
l  = [2.53 62.62 784.53]

% Hyperparameters (also GOOD)
% sf = 1242.30;
% sn = 2.2673;
% l  = [0.61 58.40 1980.30];

%%
w_init = ones(2*D,1)*sn;
R_init = eye(2*D,2*D).*sn;
b_init = ones(2*D,1).*0.0001;

%Store initial hyperparameters:
SIGMA =  RAND.*(1./l);
%% Run simulation
tic;
sim('TFlex_ISSGPcopy')
elap_time = toc;

%% Obtain results
Error = error(:)*pi/180;    % [rad] Error
Ref = reference*pi/180;     % [rad,rad/s,rad/s^2] Reference
FF  = FF(:);                % [mA] Feed forward (I-SSGP)
FB  = FB(:);                % [mA] Feed back    (PID)
Ia  = Ia(:);                % [mA] Actual current
Isp = Isp(:);               % [mA] Setpoint current
yTrain     = yTraining(:);          % [mA] Training target
xTrain     = xTraining(:,:);        % [deg,deg/s,deg/s^2] Training input
crossover  = crossover(:);
time       = [0:length(Error)-1]*ts;

%% Plot Results
FB = FB(abs(length(FF)-length(FB))+1:end);
crossover = crossover(abs(length(Ref)-length(crossover))+1:end);

% Error, FF & FB
%titleString = strcat("Incremental-Sparse Spectrum GP ","(D=",num2str(D),")");
[errorPlot,han] = plotError(ts,Ref,Error,FB,FF,'figNum',151);

% Reference
%[refPlot,ha] = plotCrossover(ts,Reference,xTrain,Error,crossover,'figNum',102);

%% Elapsed time
fprintf('\nElapsed time during simulation: %.3f s (D = %i) \n',[elap_time,D]);
fprintf("Time, using 'solve_chol_sfun' during simulation: %.3f s \n",t_end-t_learn);

%% ERROR 
Error = error(:);
N       = length(yTrain(:));
i_still = t_still/ts;
i_noFF    = 40/ts;
i_FF      = (100/ts);
if N > i_FF
    format shortEng
    fprintf('\n')
    fprintf('RMS error (10^-4 rad):\n')
    fprintf('Before I-SSGP: %f \n',rms(Error(1:i_noFF)*pi/180)*10^3)
    fprintf('After  I-SSGP: %f \n',rms(Error(i_FF:end)*pi/180)*10^3)
    format
else
    fprintf('\nNo predictions made using I-SSGP... \n')
end

RMS_ERROR = rms(Error(60/ts:180/ts))*pi/180;
MAX_ERROR = max(abs(Error(60/ts:180/ts)))*pi/180;
RMS_FB    = rms(FB(60/ts:180/ts)-mean(FB(60/ts:180/ts)));

%% Save Figures
if(fig2pdf)
    saveas(hyperPlot,fullfile(pwd,'Images','Hyperparameters.pdf'))
    saveas(errorPlot,fullfile(pwd,'Images','Error_ISSGP.pdf'))
end
if(pdf2ipe)
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end

%% SAVE SOME DATA
%saveID = 'Results\Error_sim_standstill.mat';
%saveID = 'Results\Error_sim_noFF.mat';
saveID = 'Results\Error_sim_withFF.mat';
%saveID = 'Results\Error_sim_withFFandSr2.mat';
%saveID = 'Results\Error_sim_withFF_150.mat';
%saveID = 'Results\Error_sim_withFFandSr_150.mat';
%save(saveID,'FF','FB','Error','xTrain','yTrain')

%% Online PID tuning
colors = [0,      0.4470, 0.7410;
          0.8500, 0.3250, 0.0980;
          0.9290, 0.6940, 0.1250;
          0.4940, 0.1840, 0.5560];
fontSize   = 8;
labelSize  = 11;
legendSize = 8;


%crossover = CrossOver.signals.values;
crossoverFig = figure(888); clf(crossoverFig);
ha(1,1) = subplot(3,1,1);
plot(time,Error*pi/180);
ha(1,1).YAxis.Exponent = -3;
ylim([-8 8]*1e-4)
ylabel('$e$ (rad)','Interpreter','Latex','FontSize',labelSize)
hold off

ha(2,1) = subplot(3,1,2);
hold on
plot(time,crossover(:),'LineWidth',1,'Color',colors(2,:))
plot([0,180],[20 20],':k','LineWidth',1)
plot([0,180],[ones(1,2)*PID.crossOver/(2*pi)],':k','LineWidth',1)
ylabel('$\omega_c$ (Hz)','Interpreter','Latex','FontSize',labelSize)
ylim([0 25])

ha(3,1) = subplot(3,1,3);
hold on
plot(time,FB(:)/1000,'Color',colors(3,:))
plot(time,FF(:)/1000,'-','Color',colors(4,:),'LineWidth',1);
ylabel('$u$ (mA)','Interpreter','Latex','FontSize',labelSize)
xlabel('t (s)','Interpreter','Latex','FontSize',labelSize)
legend('$u_\mathrm{FB}$','$u_\mathrm{FF}$','Interpreter','Latex','FontSize',legendSize)
hold off

[crossoverFig,ha] = subplots(crossoverFig,ha,'gabSize',[0.09, 0.04]);
set(gcf,'PaperSize',[8.4 8.4*3/4+0.3],'PaperPosition',[0.1 0.2 8.4+0.1 8.4*3/4+0.2])

%% Save figure
saveFig = 0;
if saveFig == 1
    saveas(crossoverFig,fullfile(pwd,'Images','OnlinePIDtuning.pdf'))
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end

%{
t = [0:length(Error5to35)-1]*1/1000;
figure(251),clf(251)
ha(1) = subplot(2,1,1)
plot(t,Error35to5)

ha(2) = subplot(2,1,2)
plot(t,Error5to35)

linkaxes(ha,'y')
%}