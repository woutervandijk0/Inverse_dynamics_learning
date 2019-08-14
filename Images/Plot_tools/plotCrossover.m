function [figID,han] = plotCrossover(ts,Ref,xTrain,Error,crossOver,varargin)
%% Input parser
defaultIStart      = 1;         % Index to start plotting
defaultfontSize    = 20;        % Default: plot dataset
defaultFigNum      = 0;         % 
defaultYLimits     = [-26 26];
defaultTitleString = 'Reference - Measured - Error';

p = inputParser;
checkLimits = @(x) (length(x)== 2 && max(x)<0.5);
addOptional(p,'fontSize',defaultfontSize,@(x) x>=5 );
addOptional(p,'figNum',  defaultFigNum,  @(x) x>=0 );
addOptional(p,'yLimits', defaultYLimits, @(x) checkLimits(x));
addOptional(p,'titleStr',defaultTitleString, @isstring);
addOptional(p,'iStart',  defaultIStart,  @isinteger);

parse(p,varargin{:});
fontSize    = p.Results.fontSize;
figNum      = p.Results.figNum;
ylimits     = p.Results.yLimits;
titleString = p.Results.titleStr;
ist         = p.Results.iStart;

%% Make new figure or not
if figNum ~= 0
    figID = figure(figNum); clf(figID);
else
    figID = figure;
end

%% Create plots
n = length(Ref);  % Length of measurements
t = [0:n-1]*ts;     % Time vector

% Plot Ref & Measure position
han(1,1) = subplot(3,1,1);
hold on
set(gca,'FontSize',fontSize-3);
plot(t(ist:end),Ref(ist:end,1));
plot(t(ist:end),xTrain(ist:end,1));

ylimit(1) = min([Ref(ist:end,1);xTrain(ist:end,1)]);
ylimit(2) = max([Ref(ist:end,1);xTrain(ist:end,1)]);
title(titleString,'Interpreter','Latex','FontSize',fontSize);
legend('Reference','Measured','Interpreter','Latex','FontSize',fontSize)
ylabel('(rad)','Interpreter','Latex','FontSize',fontSize);
hold off

%Plot Error
han(2,1) = subplot(3,1,2);
hold on 
set(gca,'FontSize',fontSize-3)
plot(t(ist:end),Error(ist:end));
legend('Error','Interpreter','Latex','FontSize',fontSize)
ylabel('(deg)','Interpreter','Latex','FontSize',fontSize)
hold off

%Plot cross Over
han(3,1) = subplot(3,1,3);
hold on 
set(gca,'FontSize',fontSize-3)
plot(t(ist:end),crossOver(ist:end));
legend('$\omega_c$','Interpreter','Latex','FontSize',fontSize)
ylabel('(Hz)','Interpreter','Latex','FontSize',fontSize)
xlabel('time (s)','Interpreter','Latex','FontSize',fontSize)
ylim([10 40]);
hold off


%% Nice format for 
[figID ,han] = subplots(figID,han,'gabSize',[0.09, 0.04]);