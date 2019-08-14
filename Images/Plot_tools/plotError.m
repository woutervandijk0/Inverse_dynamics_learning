function [figID,han] = plotError(ts,Error,FB,FF,varargin)
%% Input parser
defaultIStart      = 1;         % Index to start plotting
defaultfontSize    = 20;        % Default: plot dataset
defaultFigNum      = 0;         % 
defaultYLimits     = [-0.00005 0.00005];
defaultTitleString = 'Error - FB - FF';

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
n = length(Error);  % Length of measurements
t = [0:n-1]*ts;     % Time vector

% Plot Error
han(1,1) = subplot(2,1,1);
hold on
set(gca,'FontSize',fontSize-3);
plot(t(ist:end),Error(ist:end));
ylimit(1) = min([Error(ist:end);ylimits(1)]);
ylimit(2) = max([Error(ist:end);ylimits(2)]);
%plot(t1,ylimit,'--k');
%plot(t2,ylimit,'--k');
title(titleString,'Interpreter','Latex','FontSize',fontSize);
ylabel('$e$ (rad)','Interpreter','Latex','FontSize',fontSize);
hold off

%Plot FB & FF
han(2,1) = subplot(2,1,2);
hold on 
set(gca,'FontSize',fontSize-3)
plot(t(ist:end),FB(ist:end));
plot(t(ist:end),FF(ist:end),'LineWidth',1.5);
ylimit(1) = min([FB(ist:end);FF(ist:end)]);
ylimit(2) = max([FB(ist:end);FF(ist:end)]);
%plot(t1,ylimit,'--k')
%plot(t2,ylimit,'--k')
legend('$u_{FB}$','$u_{UD}$','Interpreter','Latex','FontSize',fontSize)
ylabel('(mA)','Interpreter','Latex','FontSize',fontSize)
xlabel('time (s)','Interpreter','Latex','FontSize',fontSize)
hold off

%% Nice format for 
[figID ,han] = subplots(figID,han,'gabSize',[0.09, 0.07]);