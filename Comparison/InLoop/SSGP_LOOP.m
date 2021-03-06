clear pred vari
fprintf('\n  ----  Streaming sparse GP - Bui2015  ----  \n')
%% Settings 
Z = 1;    % Size of floating frame
windowSize = 50;
%Power-EP
alpha = 0.001;    % VFE,  alpha = 0
                % SPEP, 0 < alpha < 1
                % FITC, alpha = 1
                
%% Adjust hyperparameters
sn = 1.4493;
l  = [2.4603    5.3388   38.3639];
sf = 20.6309;

hyp = [sf, l];
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

%% Data selection (intial)
%a  = xTrain(i_a)';      % Old inducing points
b  = xTrain(:,i_u)';     % New inducing points
f  = xTrain(:,i_f)';     % Training points
s  = xTrain(:,i_s)';     % Test points

%ya = yTrain(i_b)';
yb = yTrain(1,i_u)';    
yf = yTrain(1,i_f)';
ys = yTrain(1,i_s)';
err = yf;

Ma = length(b);
Mb = length(b);
Mf = length(f);
Ms = length(s);

%% Run FITC over initial window
%Initialize inducing points
u  = s(1:10:end,:);
b  = u;
Ma = length(u);
Mb = length(u);

%Build common terms
[LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs, Dff, LD, Kaa_old] = sgpBuildTerms(hyp,sn,f,yf',u,[u;s],alpha);
%Predict
[mu,var,Su] = predictSGP(hyp, [u;s], LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs);

% Split into two parts (a & s)
ma = mu(1:Ma,1);      
Saa = Su(1:Ma,1:Ma);    
mu_s = mu(Ma+1:end,1);    
var_s = var(Ma+1:end,1);  

%% Update (p indicates plus 1 timestep)
i_s_copy = i_s;
%batchLoop = i_loop(1:end-iend);
pred = zeros(1,length(i_loop));
vari = zeros(1,length(i_loop));
HYP  = zeros(100,5);
HYP(1,:) = [hyp,sn];
iterHyp = 2;
beta = 1;
%Remove 20 inducing points
%[u,Kuu,Lu,mu_u,var_u,Mu] = updateInducing(hyp,sn,u,mu_u,var_u,Kuu,u(20,:),20);
options.Display = 'none';
options.MaxIter = 10;
%sn = 0.0939

fprintf('Expected simulation time: %.3f seconds ...\n',length(i_loop)*1e-3)
tic
iter = 1;
for jj = i_loop(1:Z:end)
    %% New data
    i_sNew = (jj+1):(jj+1+Z) ;
    sNew   = xTrain(:,i_sNew)';    % New test point
    uNew   = xTrain(:,i_sNew)';    % New inducing point
    sNew   = xSp(:,i_sNew)';       % New test point
    uNew   = xSp(:,i_sNew)';
    yTrue  = yTrain(:,i_sNew)';     % Such that we can compare later
    
    fp  = xTrain(:,jj-windowSize:jj)';    % New training point
    yfp = yTrain(:,jj-windowSize:jj)';    % New training point
    
    %% Update inducing points
    a = b;
    Kaa_old = SEcov(a,a,hyp);
    %[X,NORM,minNorm,n,indUpdate] = lhcUpdate(xTrain,X,NORM,minNorm,n,Z,init)
    
    % update inducing points
    if mod(jj,250) == 0
        i_del = randi(Mb,1,1); i_new = 1;
        b(1:end-1,:)  = b([1:i_del-1,i_del+1:end],:);       % Remove from inducing points
        b(end,:) = uNew(i_new,:);
    end
%
%     i_new = 1;
%     i_b = (jj-250)+randi(250,Mb,1)';
%     b    = xTrain(:,i_b)';
%     b(end,:) = uNew(i_new,:);
    
    %% Hyperparameter update
    %{
    if mod(jj,500) == 0
    i_f = jj-1000:2:jj;
    f   = xTrain(:,i_f)';
    yf  = yTrain(:,i_f)';
    [hyp_sn nlml] = fminsearch(@(hyp) osgpNLML(hyp,sn,alpha,f,yf',a,b,Saa,ma,Kaa_old,yf'),[hyp],options);
    hyp = (1-beta)*hyp + beta*abs(hyp_sn(1:end));
    %sn  = (1-beta)*sn  + beta*abs(hyp_sn(end));
    HYP(iterHyp,:) = [hyp,sn];
    iterHyp = iterHyp+1;
    end
    %}
    
    %% update
    %Build common terms
    [~, Lb, LD, ~, LDinv_c, ~, ~, ~, ~, ~] = osgpBuildTerms(hyp,sn,fp,yfp',a,b,Saa,ma,Kaa_old,alpha);
    %Predict
    %{
    Kbbs         = SEcov(b,[b;sNew],hyp);
    [mu,var,Su]  = predictOSGP(hyp, b, [b;sNew], Lb, LD, LDinv_c, Kbbs);
    % Split into two parts (a & s)
    ma = mu(1:Mb,1);
    Saa = Su(1:Mb,1:Mb);
    mu_s = mu(Mb+1:end,1);
    var_s = var(Mb+1:end,1);
    %}
    
    Kbs         = SEcov(b,sNew,hyp);
    [mu_s,var_s,~]  = predictOSGP(hyp, b, sNew, Lb, LD, LDinv_c, Kbs);
    
    Kbb         = SEcov(b,b,hyp);
    [ma,~,Saa]  = predictOSGP(hyp, b, b, Lb, LD, LDinv_c, Kbb);
    
    pred(iter:iter+Z) = mu_s;  % Store prediction
    vari(iter:iter+Z) = var_s;
    
    yTest(iter:iter+Z)  = yTrue;      % Store True values
    iTest(iter:iter+Z)  = i_sNew;
    
    %iter = iter + 1;
    iter = iter + Z;
end
timer = toc;
t_run = timer/iter;
fprintf('Number of inducing points:     %i\n',Mb);
fprintf('Elapsed time:           total: %.3f s \n',timer);
fprintf('                per iteration: %f ms \n',t_run/1e-3);

i_end = length(i_loop);
pred = pred(1:i_end);
vari = vari(1:i_end);
yTest = yTest(1:i_end);
iTest = iTest(1:i_end);
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
yTest  = yTest.*sig_Y + mu_Y;
yloop  = yloop.*sig_Y + mu_Y;
mu_s   = mu_s.*sig_Y + mu_Y;
yf     = yf.*sig_Y + mu_Y;
pred   = pred.*sig_Y + mu_Y;
var_s  = var_s.*sig_Y + mu_Y;
vari   = vari.*sig_Y + mu_Y;
%yloop  = yloop.*sig_Y + mu_Y;
sn     = sqrt(sn.^2*sig_Y);
%}

%% Results
fSize = 12;
resultsSSGP = figure(4);clf(resultsSSGP);
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

sphandle(1,1) = subplot(2,1,1);
set(gca,'FontSize',fontSize);
hold on
%han(1) = scatter(T(1,i_f),yf(:,1),'xk');
han(1) = plot(T(1,i_loop(1:M)),yloop(1:M),'-','LineWidth',1.5,'MarkerSize',3);
han(2) = plot(iTest*ts,pred,'--k','LineWidth',1);
%scatter(u(:,1),zeros(Mu,1))
%han(4) = plot(iTest*Ts,pred + 2*sqrt(vari+sn^2),'k');
%plot(iTest*Ts,pred - 2*sqrt(vari+sn^2),'k');
%legend(han,'Initial data','Incremental data','t+1 predictions',...
%    'Predictive var.','Interpreter','Latex','FontSize',legendSize);
ylabel('(mA)','Interpreter','Latex','FontSize',labelSize)
xlabel('t (s)','Interpreter','Latex','FontSize',labelSize)
%title('Incremental FITC - Bijl2015','Interpreter','Latex','FontSize',fontSize+8)
%legend(han,'$y$','$\mu_{*,t+1}$','Interpreter','Latex')
xlim([1 35])
hold off
clear ha han

sphandle(2,1) = subplot(2,1,2);
set(gca,'FontSize',fontSize);
hold on
%han(1) = scatter(T(1,i_f),yf(:,1),'xk');
han(1) = plot(T(1,i_loop(1:M)),yloop(1:M),'-','LineWidth',1.5,'MarkerSize',3);
han(2) = plot(iTest*ts,pred,'--k','LineWidth',1);
%scatter(u(:,1),zeros(Mu,1))
%han(4) = plot(iTest*Ts,pred + 2*sqrt(vari+sn^2),'k');
%plot(iTest*Ts,pred - 2*sqrt(vari+sn^2),'k');
%legend(han,'Initial data','Incremental data','t+1 predictions',...
%    'Predictive var.','Interpreter','Latex','FontSize',legendSize);
ylabel('(mA)','Interpreter','Latex','FontSize',labelSize)
xlabel('t (s)','Interpreter','Latex','FontSize',labelSize)
%title('Incremental FITC - Bijl2015','Interpreter','Latex','FontSize',fontSize+8)
legend(han,'$y$','$\mu_{*,t+1}$','Interpreter','Latex')
xlim([18.2 18.65])
ylim([-21 8])
hold off
clear ha han

set(gcf,'PaperSize',[8.4 8.4*3/4+0.1],'PaperPosition',[0+0.3 0.2 8.4+0.3 8.4*3/4+0.2])

%[resultsSSGP,sphandle] = subplots(resultsSSGP,sphandle);

%% Hyperparameters
figure(5),clf(5)
HYP = HYP(1:iterHyp-1,:);
plot(HYP)
legend('$l_1$','$l_2$','$l_3$','$\sigma_s$','$\sigma_n$','Interpreter','Latex')

%% Plot inducing points
%{
figure(111),clf(111)
hold on
plot3(xTrain(1,i_loop),xTrain(2,i_loop),xTrain(3,i_loop),'xb')
scatter3(b(:,1),b(:,2),b(:,3),'or','filled')
%}

%% Error
%error = rms(mu_s' - yTrain(1,i_s));
%fprintf('RMS error :  Streaming Sparse GP: %f \n',error)

error = rms(pred - yTest);
fprintf('             Streaming Sparse GP: %f \n',error)

error = errorMeasure(yTest,pred);
fprintf('nRMS error:  Streaming Sparse GP: %f \n',error)
%}