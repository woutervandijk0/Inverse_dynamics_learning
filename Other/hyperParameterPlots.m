clear all, clc

%% ---------------- %% Hyperparameters Covariance Function K %% ---------------- %%
saveFig = 0;        %Safe figures

%% Create training input (random draw from GP):
N = 500;    % Number of datapoints
Q = 5;      % Number of function draws
xTrain  = linspace(0,10,N);    % Input
randX   = rand(N,Q)-1/2;       % Random vector
randY   = randn(N,1)*0;       % Noise vector

%% Create training output (random draw from GP):
% Hyperparameters 
l   = 1;            % characteristic lengthscale
sf  = sqrt(0.5);    % Signal variance
hyp = [sf,l];       % Combine

KK      = SEcov(xTrain',xTrain',hyp);   % SE Covariance kernel
KKcross = SEcov(xTrain',5,hyp);         % Cross-section of kernel
yTrue   = KK*randX;       	% Random function draw
yTrain  = yTrue + randY;   	% Add noise

% Some figure settings
fontSize   = 12;
labelSize  = 15;
titleSize  = 15;
legendSize = 12;
%{
% Plot figure
figID = figure(1),clf(figID)
set(gcf,'Color','White')
figID.Position(3) = 1300;
figID.Position(4) = 378.4;


ha(1,1) = subplot(1,3,1)
set(gca,'FontSize',fontSize);
hold on
plot(xTrain,yTrain,'k')
ylim([-6 6])
title("Draws $\sim \mathcal{N}(0,K)$",'Interpreter','Latex','FontSize',titleSize)
xlabel('$x$','Interpreter','Latex','FontSize',labelSize)
ylabel('output, $f(x)$','Interpreter','Latex','FontSize',labelSize)
hold off


ticklabels = 0:2:10;

ha(1,2) = subplot(1,3,2)
set(gca,'FontSize',fontSize);
hold on
colormap  hot
set(gcf,'Color','White')
imagesc(KK)
caxis([0 1])
plot([N,0],[0,N],'b','LineWidth',2)
xlim([0 500])
ylim([0 500])
%axis off
title(strjoin(["$K(x,x')$; $l=$",num2str(hyp(2)),", $\sigma_f^2=$",num2str(hyp(1)^2)]),'Interpreter','Latex','FontSize',titleSize)
colorbar
set(gca, 'XTick', ticks, 'XTickLabel', ticklabels)
set(gca, 'YTick', ticks, 'YTickLabel', ticklabels)
hold off

ha(1,3) = subplot(1,3,3)
set(gca,'FontSize',fontSize);
hold on
plot(xTrain,KKcross,'k')
ylim([0 1])
xlabel('$x$','Interpreter','Latex','FontSize',labelSize)
ylabel('Covariance','Interpreter','Latex','FontSize',labelSize)
title("Covariance",'Interpreter','Latex','FontSize',titleSize)
legend('$K(x,5)$','Interpreter','Latex','FontSize',titleSize,'Location','SouthEast')
hold off
ha(1,3).YTick = [0 1];

%Nice format
[figID,ha] = subplots(figID,ha,'linkAxes','off','Gabsize',[0.07, 0.02])
set(gcf,'PaperSize',[8.4*3.2 8+0.5],'PaperPosition',[-1 0.35 8.4*3.2 8])
ha(2).Position(1) = 0.4;

%% Save figures & run IPE
if saveFig == 1
    saveas(figID,fullfile(pwd,'Images','Cov_l2_sf1.pdf'))
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end
%}
% Seperate plots
% Plot figure
draws = figure(2),clf(draws)
set(gcf,'Color','White')
%figID.Position(3) = 1300;
%figID.Position(4) = 378.4;

set(gca,'FontSize',fontSize);
hold on
plot(xTrain,yTrain,'k')
ylim([-6 6])
title("Draws $\sim \mathcal{N}(0,K)$",'Interpreter','Latex','FontSize',titleSize)
xlabel('$x$','Interpreter','Latex','FontSize',labelSize)
ylabel('Output','Interpreter','Latex','FontSize',labelSize)
legend('$\mathbf{f}$','Interpreter','Latex','FontSize',legendSize)
hold off
set(gcf,'PaperSize',[8.4 8.4*2/3],'PaperPosition',[0 0 8.4 8.4*2/3])


ticklabels = 0:2:10;
ticks = linspace(1, size(KK, 2), numel(ticklabels));

covPlot = figure(3); clf(covPlot);
set(gca,'FontSize',fontSize);
hold on
colormap  hot
set(gcf,'Color','White')
imagesc(KK)
caxis([0 1])
plot([N,0],[0,N],'b','LineWidth',2)
xlim([0 500])
ylim([0 500])
%axis off
xlabel('$x$','Interpreter','Latex','FontSize',labelSize)
ylabel('$x$','Interpreter','Latex','FontSize',labelSize)
title("$K(x,x')$",'Interpreter','Latex','FontSize',titleSize)
colorbar
set(gca, 'XTick', ticks, 'XTickLabel', ticklabels)
set(gca, 'YTick', ticks, 'YTickLabel', ticklabels)
hold off
set(gcf,'PaperSize',[8.4 8.4*2/3],'PaperPosition',[0 0 8.4 8.4*2/3])

covCross = figure(4); clf(covCross);
set(gca,'FontSize',fontSize);
hold on
plot(xTrain,KKcross,'k')
ylim([0 1])
xlabel('$x$','Interpreter','Latex','FontSize',labelSize)
ylabel('Covariance','Interpreter','Latex','FontSize',labelSize)
%title("Covariance",'Interpreter','Latex','FontSize',titleSize)
legend('$K(x,5)$','Interpreter','Latex','FontSize',titleSize,'Location','SouthEast')
hold off
ha(1,3).YTick = [0 1];
set(gcf,'PaperSize',[8.4 8.4*2/3],'PaperPosition',[0 0 8.4 8.4*2/3])

%% Save figures & run IPE
saveFig = 1;
if saveFig == 1
    saveas(draws,fullfile(pwd,'Images','Draws_l1_sf05.pdf'))
    saveas(covPlot,fullfile(pwd,'Images','CovPlot_l1_sf05.pdf'))
    saveas(covCross,fullfile(pwd,'Images','covCross_l1_sf05.pdf'))
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end