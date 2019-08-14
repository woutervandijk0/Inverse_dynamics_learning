function [figID,han] = plotHyperparams(ts,hyperparam,varargin)
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
addOptional(p,'titleStr',defaultTitleString, @isstring);
addOptional(p,'iStart',  defaultIStart,  @isinteger);

parse(p,varargin{:});
fontSize    = p.Results.fontSize;
figNum      = p.Results.figNum;
titleString = p.Results.titleStr;
ist         = p.Results.iStart;

% TODO: Add legend to input parser
%       Compatible for multi dof
%% Make new figure or not
if figNum ~= 0
    figID = figure(figNum); clf(figID);
else
    figID = figure;
end

%% Create plots
n = length(hyperparam);  % Length of measurements
t = [0:n-1]*ts;     % Time vector

% Plot lengthScales
han(1,1) = subplot(2,1,1);
plot(t,hyperparam(:,1:3)','LineWidth',1.5)
legend('$l_1 \sim \theta$','$l_2 \sim \dot{\theta}$','$l_3 \sim \ddot{\theta}$',...
    'Interpreter','Latex','FontSize',fontSize)
title('Hyperparameters','Interpreter','Latex','FontSize',fontSize)

% Plot signal variance (sigma_s)
han(2,1) = subplot(2,1,2);
plot(t,hyperparam(:,4)','LineWidth',1.5)
legend('$\sigma_f$','Interpreter','Latex','FontSize',fontSize)
xlabel('t (s)','FontSize',fontSize)

[figID,han] = subplots(figID,han,'gabSize',[0.09, 0.03]);

%% Summary of final hyperparameters
ell = hyperparam(end-1,1:3);
sf = hyperparam(end-1,4);
disp('Final Hyperparameters:');
disp(['sf:  ',num2str(sf)]);
disp(['ell: ',num2str(ell)]);
format
