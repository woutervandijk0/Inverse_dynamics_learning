clear all, clc

%% ---------------- %% Marginal likelihood Plots%% ---------------- %%
saveFig = 1;        %Safe figures
pdf2ipe = 1;
%% Create training input (random draw from GP):
N = 500;    % Number of datapoints
Q = 1;       % Number of random draws
xTrain  = linspace(0,10,N);     % Input

%% Create training output (random draw from GP):
% Hyperparameters 
l   = 0.5;            % characteristic lengthscale
sf  = sqrt(1);      % Signal variance
sn  = sqrt(0.1);   % Noise Variance
hyp = [l,sf,sn];    % Combine
hyp_0 = hyp;

randX   = rand(N,Q)-1/2;        % Random vector
randY   = randn(N,1)*sn^2;         % Noise vector

KK      = SEcov(xTrain',xTrain',[sf,l])+sn.^2;   % SE Covariance kernel
KKcross = SEcov(xTrain',5,[sf,l]);         % Cross-section of kernel
yTrue   = KK*randX;       	% Random function draw
yTrain  = yTrue + randY;   	% Add noise

% Some figure settings
fontSize   = 12;
labelSize  = 15;
titleSize  = 15;
legendSize = 12;
yLim = [-6 6];

%Only training data
trainFig = figure(1); clf(trainFig);
set(gca,'FontSize',fontSize);
set(gcf,'Color','White')
hold on
plot(xTrain,yTrain,'x');
title(strjoin(["$l=?$",", $\sigma_f^2=?$"]),'Interpreter','Latex','FontSize',titleSize)
xlabel('$x$','Interpreter','Latex','FontSize',labelSize);
ylabel('Output','Interpreter','Latex','FontSize',labelSize);
legend('$\mathbf{y}$','Interpreter','Latex','FontSize',legendSize)
ylim(yLim);
hold off
set(gcf,'PaperSize',[8.4 8.4+0.2],'PaperPosition',[0 0.1 8.4 8.4+0.1])


%% Fit on training data - with different hyperparameters
% Initial Hyperparameters 
l   = 0.25;              % characteristic lengthscale
sf  = sqrt(0.6);       % Signal variance
sn  = 0.5;      % Noise Variance
hyp = [l,sf,sn];        % Combine

% Draw random samples - with initial hyperparameters
Q = 5;      % Number of random draws
randX     = rand(N,Q)-1/2;        % Random vector
KK        = SEcov(xTrain',xTrain',[sf,l]);   % SE Covariance kernel
yLatent   = KK*randX;       	% Random function draw

mlFig1 = figure(2); clf(mlFig1)
set(gca,'FontSize',fontSize);
set(gcf,'Color','White')
hold on
plot(xTrain,yTrain,'x');
plot(xTrain,yLatent,'-k');
%plot(xTrain,ones(size(xTrain))*2*sqrt(sf+sn),'--k')
%plot(xTrain,-ones(size(xTrain))*2*sqrt(sf+sn),'--k')
title(strjoin(["Maybe: $l=$",num2str(hyp(1)),", $\sigma_f^2=$",num2str(hyp(2)^2)," ?"]),'Interpreter','Latex','FontSize',titleSize)
xlabel('$x$','Interpreter','Latex','FontSize',labelSize);
ylabel('Output','Interpreter','Latex','FontSize',labelSize);
legend('$\mathbf{y}$','$\mathbf{f}$','Interpreter','Latex','FontSize',legendSize)
ylim(yLim);
hold off
set(gcf,'PaperSize',[8.4 8.4+0.2],'PaperPosition',[0 0.1 8.4 8.4+0.1])

%% Fit on training data - with different hyperparameters (again)
% Initial Hyperparameters 
l   = 2;          % characteristic lengthscale
sf  = sqrt(0.4);          % Signal variance
sn  = sqrt(0.25);          % Noise Variance
hyp = [l,sf,sn];    % Combine
%Optimize hyperparameters
lb = zeros(size(hyp));
ub = ones(size(hyp)).*100;
options = optimset;
options.Display = 'final';
options.MaxIter = 100;
%[hyp,nlml] = fmincon(@(hyp) nlmlGP(xTrain',yTrain,hyp),hyp,[],[],[],[],lb,ub,[],options)
l  = hyp(1);
sf = hyp(2);
sn = hyp(3);


KK        = SEcov(xTrain',xTrain',[sf,l]);   % SE Covariance kernel
yLatent   = KK*randX;       	% Random function draw


mlFig2 = figure(3); clf(mlFig2)
set(gca,'FontSize',fontSize);
set(gcf,'Color','White')
hold on
plot(xTrain,yTrain,'x');
plot(xTrain,yLatent,'-k');
%plot(xTrain,ones(size(xTrain))*2*sqrt(sf+sn),'--k')
%plot(xTrain,-ones(size(xTrain))*2*sqrt(sf+sn),'--k')
title(strjoin(["Maybe: $l=$",num2str(hyp(1)),", $\sigma_f^2=$",num2str(hyp(2)^2)," ?"]),'Interpreter','Latex','FontSize',titleSize)
xlabel('$x$','Interpreter','Latex','FontSize',labelSize);
ylabel('Output','Interpreter','Latex','FontSize',labelSize);
legend('$\mathbf{y}$','$\mathbf{f}$','Interpreter','Latex','FontSize',legendSize)
ylim(yLim);
hold off
set(gcf,'PaperSize',[8.4 8.4+0.2],'PaperPosition',[0 0.1 8.4 8.4+0.1])

%% Fit on training data - with correct hyperparameters 
hyp = hyp_0;
l  = hyp(1);
sf = hyp(2);
sn = hyp(3);
KK        = SEcov(xTrain',xTrain',[sf,l]);   % SE Covariance kernel
yLatent   = KK*randX;       	% Random function draw

mlFig3 = figure(4); clf(mlFig3)
set(gca,'FontSize',fontSize);
set(gcf,'Color','White')
hold on
plot(xTrain,yTrain,'x');
plot(xTrain,yLatent,'-k');
plot(xTrain,yTrue,'-k')
%plot(xTrain,ones(size(xTrain))*2*sqrt(sf+sn),'--k')
%plot(xTrain,-ones(size(xTrain))*2*sqrt(sf+sn),'--k')
title(strjoin(["Actual: $l=$",num2str(hyp(1)),", $\sigma_f^2=$",num2str(hyp(2)^2)]),'Interpreter','Latex','FontSize',titleSize)
%title('$P(\mathbf{f})$','Interpreter','Latex','FontSize',titleSize)
xlabel('$x$','Interpreter','Latex','FontSize',labelSize);
ylabel('Output','Interpreter','Latex','FontSize',labelSize);
legend('$\mathbf{y}$','$\mathbf{f}$','Interpreter','Latex','FontSize',legendSize)
%legend('$\mathbf{f}$','Interpreter','Latex','FontSize',legendSize)
ylim(yLim);
hold off
%set(gcf,'PaperSize',[8.4 8.4*2/3+0.2],'PaperPosition',[0 0.1 8.4 8.4*2/3+0.1])

set(gcf,'PaperSize',[8.4 8.4+0.2],'PaperPosition',[0 0.1 8.4 8.4+0.1])

%% Plot f(x) and y
sn = sqrt(0.25);
randY   = randn(N,1)*sn^2;         % Noise vector
yTrain = yTrain + randY;

figYTrain = figure(5); clf(figYTrain)
set(gca,'FontSize',fontSize);
set(gcf,'Color','White')
hold on
plot(xTrain(1:3:end),yTrain(1:3:end),'x');
plot(xTrain,yTrue,'-k','LineWidth',1)
%plot(xTrain,ones(size(xTrain))*2*sqrt(sf+sn),'--k')
%plot(xTrain,-ones(size(xTrain))*2*sqrt(sf+sn),'--k')
%title(strjoin(["Actual: $l=$",num2str(hyp(1)),", $\sigma_f^2=$",num2str(hyp(2)^2)]),'Interpreter','Latex','FontSize',titleSize)
xlabel('$x$','Interpreter','Latex','FontSize',labelSize);
ylabel('Output','Interpreter','Latex','FontSize',labelSize);
legend('$\mathbf{y}$','$\mathbf{f}$','Interpreter','Latex','FontSize',legendSize,'Location','NorthEast')
title('$\mathbf{y} = \mathbf{f} + \varepsilon$','Interpreter','Latex','FontSize',legendSize)

ylim(yLim);
hold off
set(gcf,'PaperSize',[8.4 8.4*2/3+0.2],'PaperPosition',[0 0.1 8.4 8.4*2/3+0.1])

%% Save figures & run IPE
if saveFig == 1
    %saveas(figYTrain,fullfile(pwd,'Images','goalGP.pdf'))
    saveas(trainFig,fullfile(pwd,'Images','margLikFig0.pdf'))
    saveas(mlFig1,fullfile(pwd,'Images','margLikFig1.pdf'))
    saveas(mlFig2,fullfile(pwd,'Images','margLikFig2.pdf'))
    saveas(mlFig3,fullfile(pwd,'Images','margLikFig3.pdf'))
end
if pdf2ipe == 1
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end
%%
%    saveas(mlFig3,fullfile(pwd,'Images','posterior.pdf'))

