clc, clear all

%% ---------------- %% Marginal likelihood Plots%% ---------------- %%
saveFig = 0;        %Safe figures
pdf2ipe = 0;
%% Create training input (random draw from GP):
N = 500;    % Number of datapoints
Q = 6;      % Number of random draws
xTrain  = linspace(0,10,N);     % Input
xTrue   = xTrain;

%% Create training output (random draw from GP):
% Hyperparameters 
l   = 0.4;            % characteristic lengthscale
sf  = sqrt(1);      % Signal variance
sn  = sqrt(0.25);   % Noise Variance
sn  = sqrt(0.1);   % Noise Variance
hyp = [l,sf,sn];    % Combine
hyp_0 = hyp;

randX   = (rand(N,Q)-1/2);        % Random vector
randY   = randn(N,1)*sn^2;         % Noise vector

KK      = SEcov(xTrain',xTrain',[sf,l]);   % SE Covariance kernel
KKcross = SEcov(xTrain',5,[sf,l]);         % Cross-section of kernel
yTrue   = KK*randX;       	% Random function draw
yTrain  = yTrue + randY;   	% Add noise

fontSize   = 12;
labelSize  = 15;
titleSize  = 15;
legendSize = 12;
yLim = [-4 6];

%% Resample training data
i = 100+randi(300,20,1);
%i = round(linspace(150,350,15))
N = length(i);
xPredict = xTrain;
xTrain = xTrain(i)
yTrain = yTrain(i,1)
%%
KK = sf^2.*exp(-1/2*(xTrain-xTrain').^2./l.^2)+eye(N).*sn.^2
%KK   = SEcov(xTrain',xTrain',[sf,l])+eye(N).*sn.^2;   % SE Covariance kernel
k    = SEcov(xTrain',xPredict',[sf,l]);
%k_ff = SEcov(xPredict',xPredict',[sf,l]);
k_ff = sf^2.*exp(-1/2*(xPredict-xPredict').^2./l.^2);

L = chol(KK);
%alpha = L'\(L\yTrain);
alpha = solve_chol(L,yTrain);

%Predictive mean
mu = k'*alpha;
%Predictive variance
%v = solve_lowerTriangular(L,k);
v = L'\k;
var = k_ff - (v'*v);


priorFig = figure(2); clf(priorFig);
set(gcf,'Color','White')
hold on
set(gca,'FontSize',fontSize);
plot(xTrue,yTrue(:,2:5),'k');
title('Prior','Interpreter','Latex','FontSize',titleSize)
xlabel('$x$','Interpreter','Latex','FontSize',labelSize);
ylabel('Output','Interpreter','Latex','FontSize',labelSize);
ylim(yLim);
legend('$\mathcal{N}(\mu,\Sigma)$','Interpreter','Latex','FontSize',legendSize)
hold off
set(gcf,'PaperSize',[8.4 8.4],'PaperPosition',[0 0 8.4 8.4])

postFig1 = figure(3); clf(postFig1);
set(gcf,'Color','White')
hold on
set(gca,'FontSize',fontSize);
%li(4) = plot(xTrue,yTrue(:,1),'k','LineWidth',1.5);
li(1) = plot(xTrain,yTrain,'+','MarkerSize',8,'LineWidth',1);
li(2) = plot(xPredict,mu,'-r','LineWidth',1.5)
li(3) = plot(xPredict,mu + 2*sqrt(diag(var)+sn.^2),'--k','LineWidth',1);
plot(xPredict,mu - 2*sqrt(diag(var)+sn.^2),'--k','LineWidth',1);
title('Posterior','Interpreter','Latex','FontSize',titleSize)
xlabel('$x$','Interpreter','Latex','FontSize',labelSize);
ylabel('Output','Interpreter','Latex','FontSize',labelSize);
%legend(li,'$\mathbf{y}$','$\mu$','$2\sigma$','$\mathbf{f}_\mathrm{true}$','Interpreter','Latex','FontSize',legendSize)
legend(li,'$\mathbf{y}$','$\mu$','$2\sigma$','Interpreter','Latex','FontSize',legendSize)
ylim(yLim);
hold off
set(gcf,'PaperSize',[8.4 8.4],'PaperPosition',[0 0 8.4 8.4])


drawPost = mu + var*randX;
postFig2 = figure(4); clf(postFig2);
set(gcf,'Color','White')
hold on
set(gca,'FontSize',fontSize);
li(1) = plot(xTrain,yTrain,'+','MarkerSize',8,'LineWidth',1);
li(2:7) = plot(xTrue,drawPost,'-k')
li(2) = plot(xPredict,mu,'-r','LineWidth',1.5)
li(3) = plot(xPredict,mu + 2*sqrt(diag(var)+sn.^2),'--k','LineWidth',1);
plot(xPredict,mu - 2*sqrt(diag(var)+sn.^2),'--k','LineWidth',1);
%title('Draws $\sim \mathcal{N}(\mu,\Sigma)$','Interpreter','Latex','FontSize',titleSize)
title('Posterior','Interpreter','Latex','FontSize',titleSize)
xlabel('$x$','Interpreter','Latex','FontSize',labelSize);
ylabel('Output','Interpreter','Latex','FontSize',labelSize);
legend(li,'$\mathbf{y}$','$\mu$','$2\sigma$','$\mathbf{f}$','Interpreter','Latex','FontSize',legendSize)
ylim(yLim);
hold off

%[priorFig,ha] = subplots(priorFig,ha,'linkAxes','xy','Gabsize',[0.02, 0.02])
set(gcf,'PaperSize',[8.4 8.4],'PaperPosition',[0 0 8.4 8.4])

%%
posterior = figure(555),clf(posterior)
hold on
set(gca,'FontSize',fontSize);
li(2:7) = plot(xTrue,drawPost,'-k')
li(1)   = plot(xTrain,yTrain,'+');
%li(2) = plot(xPredict,mu,'-r','LineWidth',1.5)
%li(3) = plot(xPredict,mu + 2*sqrt(diag(var)+sn.^2),'--k','LineWidth',1);
%plot(xPredict,mu - 2*sqrt(diag(var)+sn.^2),'--k','LineWidth',1);
%title('Draws $\sim \mathcal{N}(\mu,\Sigma)$','Interpreter','Latex','FontSize',titleSize)
title('$P(\mathbf{f}|\mathbf{y})$','Interpreter','Latex','FontSize',titleSize)
xlabel('$x$','Interpreter','Latex','FontSize',labelSize);
ylabel('Output','Interpreter','Latex','FontSize',labelSize);
legend(li,'$\mathbf{y}$','$\mathbf{f}$','Interpreter','Latex','FontSize',legendSize)
ylim(yLim);
hold off
set(gcf,'PaperSize',[8.4 8.4*2/3+0.2],'PaperPosition',[0 0.1 8.4 8.4*2/3+0.1])

% saveas(posterior,fullfile(pwd,'Images','posterior.pdf'))
% pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})




%% Save figures & run IPE
if saveFig == 1
    saveas(priorFig,fullfile(pwd,'Images','GP_prior.pdf'))
    saveas(postFig1,fullfile(pwd,'Images','GP_post1.pdf'))
    saveas(postFig2,fullfile(pwd,'Images','GP_post2.pdf'))    
end
if pdf2ipe == 1
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end