clc, clear all, close all

%% Create training input (random draw from GP):
N = 5000;    % Number of datapoints
Q = 1;      % Number of random draws
xTrain  = linspace(0,10,N);     % Input
xTrue   = xTrain;

%% Create training output (random draw from GP):
% Hyperparameters 
l   = 0.4;            % characteristic lengthscale
sf  = sqrt(1);      % Signal variance
sn  = sqrt(0.25);   % Noise Variance
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
i = 100+randi(200,500,1);
i = 1:length(xTrain);
N = length(i);
xPredict = xTrain;
xTrain = xTrain(i);
yTrain = yTrain(i,1);

%% Sparse spectum GP
D = 150;
n = 1;
RAND  = randn(D,n); % 
SIGMA = RAND.*(1./l);

x  = xTrain';
y  = yTrain;
xs = xPredict';

phi   = sf^2./sqrt(D) .*[cos(SIGMA*x')',...
                       sin(SIGMA*x')']';
                   
phi_s = sf^2./sqrt(D) .*[cos(SIGMA*xs')',...
                       sin(SIGMA*xs')']';
                   
A = phi*phi' + eye(2*D).*(D*sn^2/(sf^2));
La = chol(A,'lower');

mu = (La\phi_s)'*(La\phi)*y;
var = sn^2. * ( 1 + (La\phi_s)'*(La\phi_s));

%% plot
trainFig = figure(1); clf(trainFig);
set(gca,'FontSize',fontSize);
set(gcf,'Color','White')
hold on
plot(xTrain,yTrain,'x');
plot(xPredict,mu);
plot(xPredict,mu+2*sqrt(diag(var)))
plot(xPredict,mu-2*sqrt(diag(var)))


xlabel('$x$','Interpreter','Latex','FontSize',labelSize);
ylabel('output','Interpreter','Latex','FontSize',labelSize);
legend('$\mathbf{y}$','Interpreter','Latex','FontSize',legendSize)
ylim(yLim);
hold off
set(gcf,'PaperSize',[8.4 8.4+0.2],'PaperPosition',[0 0.1 8.4 8.4+0.1])

%%
