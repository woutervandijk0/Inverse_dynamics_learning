
fprintf('\n  ----  Incremental Sparse Spectum GP - Bijl2015  ----   \n')
%% Normalize data
%{

% X
mu_X   = mean(xTrain');
sig_X  = std(xTrain');
%xTrain = ((xTrain' - mu_X) ./ sig_X)';
% Y
mu_Y   = mean(yTrain');
sig_Y  = std(yTrain');
%yTrain = ((yTrain' - mu_Y) ./ sig_Y)';
%}
%% (Hyper)parameters 
%{
%Hyperparameters 
sn  = 1;          % Noise variance
sf   = 0.5;           % Signal variance
l    = [ones(1,dof)];   % characteristic lengthscale
%Combine into 1 vector
hyp  = [sf,l];

%overwrite hyperparam
%sn  = 0.0605;
%hyp = [1.4054    1.6466    1.5730    0.8754];
%}
sn = sn_old;
%sn = 1

%% Data selection (intial)

f  = xTrain(:,i_f)';
u  = xTrain(:,i_u)';
s  = xTrain(:,i_s)';
loop   = xTrain(:,i_loop)';

yf = yTrain(:,i_f)';
ys = yTrain(:,i_s)';
yloop   = yTrain(:,i_loop)';

%% I-SSGP (fist part)
% Number of random features
D = 500;   
sn2 = sn.^2;
sf  = hyp(1);

% Preallocate vectors and matrices
mu_s   = zeros(length(i_s),1);
var_s  = zeros(length(i_s),1);

w    = zeros(2*D,1);
b    = zeros(2*D,1);
v    = zeros(2*D,1);
phi  = zeros(2*D,1);

RAND  = randn(D,dof);
%rVec  = randn(D,1);
%SIGMA  = [rVec./hyp(2),rVec./hyp(3),rVec./hyp(4)];
R     = eye(2*D,2*D)*sn^2;
SIGMA = RAND.*(1./(hyp(1,2:end)));

% Training Loop
for ii = 1:length(i_f)
    s_n   = f(ii,:);
    ys_n  = yf(ii,:);
    phi = sf./sqrt(D) .*[cos(SIGMA*s_n')',...
                         sin(SIGMA*s_n')']';
    %Update posterior
    b =  b + phi*ys_n;
    R = cholupdate(R,phi);
    w = solve_chol(R,b);
end

%Prediction loop
iter = 1;
for ii = 1:length(i_s)
    s_n   = s(ii,:);
    ys_n  = ys(ii,:);
    phi   = sf./sqrt(D) .*[cos(SIGMA*s_n')',...
                         sin(SIGMA*s_n')']';
    %Prediction
    mu_s(iter)   = dot(w,phi);
    v            = R'\phi;
    var_s(iter)  = sn2.*(1+dot(v,v));
    iter = iter + 1;
end

%% True loop
%Prediction loop
tic;
iter = 1;
for jj = i_loop
    % New data
    i_sNew = jj+1;
    sNew   = xTrain(:,i_sNew)';    % New test point  
    %sNew   = xSetpoint(:,i_sNew)';   % New test point (from setpoint)
    yTrue  = yTrain(:,i_sNew)';     % Such that we can compare later

    fp  = xTrain(:,jj)';    % New training point
    yfp = yTrain(:,jj)';    % New training point
    
%    s_n   = s(jj,:);
%    ys_n  = ys(jj,:);
    phi = sf./sqrt(D) .*[cos(SIGMA*sNew')',...
                         sin(SIGMA*sNew')']';
    %Prediction
    pred(iter)   = dot(w,phi);
    v            = R'\phi;
    vari(iter)   = sn2.*(1+dot(v,v));
    
    yTest(iter)  = yTrue;
    iTest(iter)  = i_sNew;
    
    %Update posterior
    b =  b + phi*yfp;
    R = cholupdate(R,phi);
    w = solve_chol(R,b);
    
    iter = iter + 1;
end
timer = toc;
t_run = timer/iter;
fprintf('Number of features:            %i\n',D);
fprintf('Elapsed time:           total: %.3f s \n',timer);
fprintf('                per iteration: %f ms \n',t_run/1e-3);


%% scale back up
%{
% X
xTrain = xTrain.*sig_X' + mu_X';
f      = f.*sig_X + mu_X;
s      = s.*sig_X + mu_X;
loop   = loop.*sig_X + mu_X;
u      = u.*sig_X + mu_X;

%Y
yTrain = yTrain.*sig_Y + mu_Y;
mu_s   = mu_s.*sig_Y + mu_Y;
yf     = yf.*sig_Y + mu_Y;
pred   = pred.*sig_Y + mu_Y;
var_s  = var_s.*sig_Y + mu_Y;
vari   = vari.*sig_Y + mu_Y;
yloop  = yloop.*sig_Y + mu_Y;
%sn     = sqrt(sn.^2*sig_Y);
%}

%% Results
fSize = 12;
resultsIFITC = figure(3);clf(resultsIFITC);
%{
sphandle(1,1) = subplot(2,1,1);
hold on
ha(1) = scatter(T(1,i_f),yf(:,1),'xb');
%ha(2).MarkerFaceAlpha = .6;
%ha(2).MarkerEdgeAlpha = .6;
%ha(1) = plot(xTrain(1,i_plot),yTrue(1,i_plot),'-k','LineWidth',1.5);
ha(2) = plot(T(1,i_s),mu_s,'r','LineWidth',1.5);
ha(3) = plot(T(1,i_s),mu_s + 2*sqrt(var_s+ sn^2),'k');
plot(T(1,i_s),mu_s - 2*sqrt(var_s+ sn^2),'k');
%ha(2) = scatter(u_old(:,1),zeros(size(u,1),1),ones(size(u,1),1)*10,'ok','filled');
legend(ha,'Initial data','Predicted mean',...
    'Predictive var.','Interpreter','Latex','FontSize',fSize);
title('Incremental Sparse Spectrum GP - Gijsberts2013','Interpreter','Latex','FontSize',fSize+8)
ylabel('y','Interpreter','Latex','FontSize',fSize+4)
hold off
clear ha
%}

sphandle(1,1) = subplot(1,1,1);
hold on
han(2) = scatter(T(1,i_f),yf(:,1),'xk');
han(2).MarkerFaceAlpha = .6;
han(2).MarkerEdgeAlpha = .6;
han(1) = scatter(iTest*Ts,yloop(:,1),'xb');
han(3) = plot(iTest*Ts,pred,'r','LineWidth',1.5);
%scatter(u(:,1),zeros(Mu,1))
han(4) = plot(iTest*Ts,pred + 2*sqrt(vari+sn^2),'k');
plot(iTest*Ts,pred - 2*sqrt(vari+sn^2),'k');
%legend(han,'Initial data','Incremental data','t+1 predictions',...
%    'Predictive var.','Interpreter','Latex','FontSize',fSize);
ylabel('y','Interpreter','Latex','FontSize',fSize+4)
xlabel('t (s)','Interpreter','Latex','FontSize',fSize+4)
title('Incremental Sparse Spectrum GP - Gijsberts2013','Interpreter','Latex','FontSize',fSize+8)
hold off
clear ha han
[resultsIFITC,sphandle] = subplots(resultsIFITC,sphandle);

%% Error
error = rms(mu_s' - yTrain(1,i_s));
fprintf('RMS error :              SSGP: %f \n',error)

error = rms(pred - yTest);
fprintf('             Incremental SSGP: %f \n',error)

error = errorMeasure(yTest,pred);
fprintf('nRMS error:  Incremental SSGP: %f \n',error)
%}

