clc, clear all, close all

%% (Hyper)parameters 
%Hyperparameters 
l   = 1;        % characteristic lengthscale
sf  = 2;         % Signal variance
sn  = 5;       % Noise variance
sn2 = sn^2;
hyp = [sf,l];
alpha  = 0.5;   % VFE,  alpha = 0

%% Create training data (random draw from GP):
%
N = 5000;
xTrain = linspace(0,20,N);           % Input
KK      = SEcov(xTrain',xTrain',hyp);   % SE covariance kernel
randX   = rand(N,1)-1/2;             % Random vector
yTrue   = KK*randX + 5.*cos(xTrain'/20*pi);                     % Underlying function
yTrain  = yTrue + randn(N,1)*sn;     % Add noise
%}

yTrain  = yTrain;
yTrue   = yTrue;
[dof, N] = size(xTrain);

plot(xTrain,yTrain,'.')

%Normalize data
%{
mu_X   = mean(xTrain');
sig_X  = std(xTrain');
xTrain = ((xTrain' - mu_X) ./ sig_X)';

mu_Y   = mean(yTrain');
sig_Y  = std(yTrain');
yTrain = ((yTrain' - mu_Y) ./ sig_Y)';
yTrue  = ((yTrue' - mu_Y) ./ sig_Y)';
sn     = 0.1/sig_Y;       % Noise variance
sn2    = sn^2;

%}
%
%% FITC
i_f = 1:10:N;
i_s = [1:1:N];
i_b = [1:10:N];
jitter = 1e-5;

%a  = xTrain(i_a)';      % Old inducing points
b  = xTrain(:,i_b)';     % New inducing points
f  = xTrain(:,i_f)';     % Training points
s  = xTrain(:,i_s)';     % Test points

%ya = yTrain(i_b)';
yb = yTrain(i_b)';    
yf = yTrain(i_f)';
ys = yTrain(i_s)';
err = yf;

tic
%Ma = length(a);
Mb = length(b);
Mf = length(f);
Ms = length(s);

Kff     = SEcov(f,f,hyp);
Kfdiag  = diag(Kff);
Kbf     = SEcov(b,f,hyp);
Kbb     = SEcov(b,b,hyp) + eye(Mb)*jitter;
Kbs     = SEcov(b,s,hyp);

Lb          = chol(Kbb,'lower');
Lbinv_Kbf   = solve_lowerTriangular(Lb,Kbf);

Lbinv_Kbs   = solve_lowerTriangular(Lb, Kbs);

Qfdiag      = Kfdiag - diag(Lbinv_Kbf'*Lbinv_Kbf);
%Qfdiag      = Kfdiag' - sum(Lbinv_Kbf.^2);
Dff         = sn + alpha.*Qfdiag;
Lbinv_Kbf_LDff = Lbinv_Kbf./sqrt(Dff');

D = eye(Mb) + Lbinv_Kbf_LDff*Lbinv_Kbf_LDff';
LD = chol(D,'lower');

LDinv_Lbinv_Kbs = solve_lowerTriangular(LD, Lbinv_Kbs);
LDinv_Lbinv_Kbf = solve_lowerTriangular(LD,Lbinv_Kbf);

Sinv_y          = (yf./Dff')';
c               = Lbinv_Kbf*Sinv_y;
LDinv_Lbinv_Kbf_c  = LDinv_Lbinv_Kbf*Sinv_y;
LDinv_c         = solve_lowerTriangular(LD,c);


%% Approximate log marginal Likelihood
%{
bound = 0;
% constant term
bound = - 0.5*Mf*log(2*pi);
% quadratic term
bound = bound - 0.5 * sum(err.^2/ Dff');
bound = bound + 0.5 * sum(LDinv_c.^2);

% log det term
bound = bound - 0.5 * sum(log(Dff));
bound = bound - sum(log(diag(LD)));

% trace-like term
bound = bound - 0.5*(1-alpha)/alpha * sum(log(Dff./sn));
%}
%% Prediction 
%Predictive mean
%m = LDinv_Lbinv_Kbs'*LDinv_Lbinv_Kbf_c;
m = LDinv_Lbinv_Kbs'*LDinv_c;

%Prediction variance (matrix)
Kss  = SEcov(s,s,hyp) + eye(Ms)*jitter;
var1 = Kss;
var2 = -Lbinv_Kbs'*Lbinv_Kbs;
var3 = LDinv_Lbinv_Kbs'*LDinv_Lbinv_Kbs;
Su   = var1 + var2 + var3;

%Prediction variance (vector)
var  = diag(Su);
toc
%% Plot result 
fSize = 20
resultsSSGP = figure(2); clf(2);
set(gcf,'Color','White')
hold on
ha(2) = scatter(xTrain,yTrain,'ob','filled');
ha(2).MarkerFaceAlpha = .1;
ha(2).MarkerEdgeAlpha = .1;
ha(4) = plot(s(:,1),m,'-k','LineWidth',2);
ha(5) = plot(s(:,1),m + 2*sqrt(var+sn2),'-k');
        plot(s(:,1),m - 2*sqrt(var+sn2),'-k');
axis off
hold off
set(figure(2),'Position',[565 100.2000 560 620])

%}

