function [figID,han] = plotDisturbances(ts,position,noiseIn,noiseOut,hysteresis,cogging,varargin)
%% Input parser
defaultIStart      = 1;         % Index to start plotting
defaultfontSize    = 20;        % Default: plot dataset
defaultFigNum      = 0;         % 
defaultTitleString = 'Disturbances';

p = inputParser;
checkLimits = @(x) (length(x)== 2 && max(x)<0.5);
addOptional(p,'fontSize',defaultfontSize,@(x) x>=5 );
addOptional(p,'figNum',  defaultFigNum,  @(x) x>=0 );
addOptional(p,'titleStr',defaultTitleString, @isstring);
addOptional(p,'iStart',  defaultIStart,  @isinteger);

parse(p,varargin{:});
fontSize    = p.Results.fontSize;
figNum      = p.Results.figNum;
titleString = p.Results.titleStr;
ist         = p.Results.iStart;

%% Make new figure or not
if figNum ~= 0
    figID = figure(figNum); clf(figID);
else
    figID = figure;
end

%% Create plots
n = length(noiseIn);  % Length of measurements
t = [0:n-1]*ts;     % Time vector
% Plot Position
han(1,1) = subplot(5,1,1);
hold on
set(gca,'FontSize',fontSize-3);
plot(t,position,'LineWidth',1.5);
title(titleString,'Interpreter','Latex','FontSize',fontSize);
ylabel('$(deg)$','Interpreter','Latex','FontSize',fontSize);
legend('$y$','Interpreter','Latex');
hold off

% Plot Disturbances
han(2,1) = subplot(5,1,2);
hold on
set(gca,'FontSize',fontSize-3);
plot(t,noiseIn,'Color',[0.8500, 0.3250, 0.0980],'LineWidth',1.5);
plot(t,noiseOut,'Color',[0.4940, 0.1840, 0.5560],'LineWidth',1.5);
ylabel('$(mA)$','Interpreter','Latex','FontSize',fontSize);
legend('$\mathrm{Noise}_\mathrm{in}$','$\mathrm{Noise}_\mathrm{out}$','Interpreter','Latex');
hold off

han(3,1) = subplot(5,1,4);
hold on
set(gca,'FontSize',fontSize-3);
plot(t,cogging,'Color',[0.9290, 0.6940, 0.1250],'LineWidth',1.5);
plot(t,hysteresis,'Color',	[0.4660, 0.6740, 0.1880],'LineWidth',1.5);
ylabel('$(mA)$','Interpreter','Latex','FontSize',fontSize);
legend('$\mathrm{Cogging}$','$\mathrm{Hysteresis}$','Interpreter','Latex');
ylim([-28 28])
hold off

%% Nice format for 
[figID ,han] = subplots(figID,han,'gabSize',[0.09, 0.07]);