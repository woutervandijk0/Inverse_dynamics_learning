%% Data selection
i_f = [1:200];
i_s = [1:1:700];
i_loop  = [200:400];
i_plot  = [1:700];
i_total = [i_f,i_loop];


f  = xTrain(:,i_f)';
s  = xTrain(:,i_s)';
loop = xTrain(:,i_loop)';

yf = yTrain(:,i_f)';
ys = yTrain(:,i_s)';
yloop = yTrain(:,i_loop)';

[dof, N] = size(xTrain);

%% I-SSGP
fprintf('  ----  Incremental Sparse Spectrum GP - Bijl2015  ----   \n')
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
    %w = R\(R'\b);
end

%Prediction loop
iter = 1;
for ii = 1:length(i_s)
    s_n   = s(ii,:);
    ys_n  = ys(ii,:);
    phi = sf./sqrt(D) .*[cos(SIGMA*s_n')',...
                         sin(SIGMA*s_n')']';
    %Prediction
    %
    mu_s(iter)   = dot(w,phi);
    v            = R'\phi;
    var_s(iter)  = sn2.*(1+dot(v,v));
    %}
    
    %Prediction v2
    %{
    %v = solve_lowerTriangular(R',phi);
    %w = solve_lowerTriangular(R',b);
    v            = R'\phi;
    w            = R'\b;
    mu_s(iter)   = v'*w;
    var_s(iter)  = sn2.*(1+dot(v,v));
    %}
    iter = iter + 1;
end

%% Plot results
clear ha
resultsISSGP = figure(3); clf(resultsISSGP)
sphandle(1,1) = subplot(2,1,1);
set(gca,'FontSize',fontSize);
hold on
ha(2) = plot(f(:,1),yf(:,1),'x','MarkerSize',2);
ha(1) = plot(xTrain(1,i_plot),yTrue(1,i_plot),'-k','LineWidth',1);
ha(3) = plot(s(:,1),mu_s,'-','LineWidth',1.5);
ha(4) = plot(s(:,1),mu_s + 2*sqrt(var_s+sn2),'k');
        plot(s(:,1),mu_s - 2*sqrt(var_s+sn2),'k');
legend(ha,'$f_\mathrm{true}$','y','$\mu_{*}$','$\Sigma_{*}$','Interpreter','Latex','FontSize',legendSize);
title('Incremental Sparse Spectrum GP - Gijsberts2013','Interpreter','Latex','FontSize',fontSize+8)
ylabel('y','Interpreter','Latex','FontSize',labelSize)
ylim([-5 5])
xlim([0 2.7])
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
set(gca,'FontSize',fontSize);
hold on
%ha(2) = plot(f(:,1),yf(:,1),'xk','MarkerSize',1);
ha(2) = plot(loop(:,1),yloop(:,1),'x','MarkerSize',2);
ha(1) = plot(xTrain(1,i_plot),yTrue(1,i_plot),'-k','LineWidth',1);
ha(3) = plot(s(:,1),mu_s,'-','LineWidth',1.5);
ha(4) = plot(s(:,1),mu_s + 2*sqrt(var_s+sn2),'k');
        plot(s(:,1),mu_s - 2*sqrt(var_s+sn2),'k');
%legend(ha,'$f_\mathrm{true}$','y','$\mu_{*}$','$\Sigma_{*}$','Interpreter','Latex','FontSize',legendSize);
ylabel('y','Interpreter','Latex','FontSize',labelSize)
xlabel('t (s)','Interpreter','Latex','FontSize',labelSize)
ylim([-5 5])
xlim([0 2.7])
hold off
clear ha

[resultsISSGP,sphandle] = subplots(resultsISSGP,sphandle,'gabSize',[0.09, 0.04]);
set(gcf,'PaperSize',[8.4 8.4*3/4+0.1],'PaperPosition',[0 0.2 8.4 8.4*3/4+0.2])

%% Error
error = rms(mu_s - yTrain(1,i_s)');
fprintf('RMS error:  complete interval: %f \n',error)

error = rms(mu_s(i_total) - yTrain(1,i_total)');
fprintf('            measured interval: %f \n\n',error)

% For SSGP.m
xTrain  = xTrain;
yTrain  = yTrain';
yTrue   = yTrue';