%% Data selection
i_f = [1:500];
i_s = [1:10:500];
i_loop  = [600:700];
i_plot  = [1:1000];

f  = xTrain(:,i_f)';
s  = xTrain(:,i_s)';
loop = xTrain(:,i_loop)';

yf = yTrain(:,i_f)';
ys = yTrain(:,i_s)';
yloop = yTrain(:,i_loop)';

[dof, N] = size(xTrain);

%% I-SSGP
fprintf('  ----  Streaming sparse GP - Bui2015  ----   \n')
 % Number of random features
D = 50;   
sn2 = sn.^2;

% Preallocate vectors and matrices
mu_s   = zeros(length(i_s),1);
var_s  = zeros(length(i_s),1);

w    = zeros(2*D,1);
b    = zeros(2*D,1);
v    = zeros(2*D,1);
phi  = zeros(2*D,1);

RAND  = randn(D,dof);
R     = eye(2*D,2*D)*sn;
SIGMA = RAND.*(1./hyp(1,2:end));

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
    phi = sf./sqrt(D) .*[cos(SIGMA*s_n')',...
                         sin(SIGMA*s_n')']';
    %Prediction
    mu_s(iter)   = dot(w,phi);
    v            = R'\phi;
    var_s(iter)  = sn2.*(1+dot(v,v));
    iter = iter + 1;
end

%% Plot results
clear ha
resultsISSGP = figure(3); clf(resultsISSGP)
sphandle(1,1) = subplot(2,1,1);
hold on
ha(2) = scatter(f(:,1),yf(:,1),'xb');
ha(1) = plot(xTrain(1,i_plot),yTrue(1,i_plot),'-k','LineWidth',1.5);
ha(3) = plot(s(:,1),mu_s,'r','LineWidth',1.5);
ha(4) = plot(s(:,1),mu_s + 2*sqrt(var_s+sn2),'k');
        plot(s(:,1),mu_s - 2*sqrt(var_s+sn2),'k');
legend(ha,'True function','Incr. data','Predicted mean',...
    'Predictive var.','Interpreter','Latex','FontSize',fSize);
title('Incremental Sparse Spectrum GP - Gijsberts2013','Interpreter','Latex','FontSize',fSize+8)
ylabel('y','Interpreter','Latex','FontSize',fSize+4)
hold off
clear ha

%% Continue on extra window
i_s = [1:700];
f   = xTrain(:,i_f)';     % Training points
s   = xTrain(:,i_s)';     % Test points
a   = b;
yf  = yTrain(i_f)';
ys  = yTrain(i_s)';


tic
% Training Loop
for ii = 1:length(i_loop)
    s_n   = loop(ii,:);
    ys_n  = yloop(ii,:);
    phi = sf./sqrt(D) .*[cos(SIGMA*s_n')',...
                         sin(SIGMA*s_n')']';
    %Update posterior
    b =  b + phi*ys_n;
    R = cholupdate(R,phi);
    w = solve_chol(R,b);
end

% Prediction loop 
iter = 1;
for ii = 1:length(i_s)
    s_n   = s(ii,:);
    ys_n  = ys(ii,:);
    phi = sf./sqrt(D) .*[cos(SIGMA*s_n')',...
                         sin(SIGMA*s_n')']';
    %Prediction
    mu_s(iter)   = dot(w,phi);
    v            = R'\phi;
    var_s(iter)  = sn2.*(1+dot(v,v));
    iter = iter + 1;
end
timer = toc;
t_run = toc/(iter);
fprintf('Number of features:            %i\n',D);
fprintf('Elapsed time:           total: %.5f ms\n',timer/1e-3)
fprintf('                per iteration: %f ms \n',t_run/1e-3)

%% Plot results
sphandle(2,1) = subplot(2,1,2);
hold on
ha(2) = scatter(f(:,1),yf(:,1),'xk');
ha(2).MarkerFaceAlpha = .6;
ha(2).MarkerEdgeAlpha = .6;
ha(3) = scatter(loop(:,1),yloop(:,1),'xb');
ha(1) = plot(xTrain(1,i_plot),yTrue(1,i_plot),'-k','LineWidth',1.5);
ha(4) = plot(s(:,1),mu_s,'r','LineWidth',1.5);
ha(5) = plot(s(:,1),mu_s + 2*sqrt(var_s+sn2),'k');
        plot(s(:,1),mu_s - 2*sqrt(var_s+sn2),'k');
legend(ha,'True function','Incr. data','Incr. data','Predicted mean',...
    'Predictive var.','Interpreter','Latex','FontSize',fSize);
ylabel('y','Interpreter','Latex','FontSize',fSize+4)
hold off
clear ha

[resultsISSGP,sphandle] = subplots(resultsISSGP,sphandle);

%% Error
error = rms(mu_s - yTrain(1,i_s)');
fprintf('RMS error:  complete interval: %f \n',error)

error = rms(mu_s(i_total) - yTrain(1,i_total)');
fprintf('            measured interval: %f \n\n',error)

% For SSGP.m
xTrain  = xTrain;
yTrain  = yTrain';
yTrue   = yTrue';