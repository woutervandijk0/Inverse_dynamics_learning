clear pred vari
fprintf('  ----  Streaming sparse GP - Bui2015  ----  \n')
%% Settings 
Z = 1;    % Size of floating frame
windowSize = 200;
%Power-EP
alpha = 0.1;    % VFE,  alpha = 0
                % SPEP, 0 < alpha < 1
                % FITC, alpha = 1
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
u  = s(1:5:end,:);
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
for jj = i_loop(1:windowSize:end)-1
    %% New data
    i_sNew = (jj-windowSize):(jj) ;
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
   Ma = length(a);
   M_old = floor(Ma*0.7);
   a_old = a(unique(randi(Ma,M_old,1)),:);
   M_new = Ma-length(a_old);
   a_new = fp(randi(Ma,M_new,1),:);
   b = [a_old; a_new];
   
   %
   %i_del = randi(Mb,1,1); i_new = 1;
   %b(1:end-1,:)  = b([1:i_del-1,i_del+1:end],:);       % Remove from inducing points
   %b(end,:) = uNew(i_new,:);
   %
   %     i_new = 1;
   %     i_b = (jj-250)+randi(250,Mb,1)';
   %     b    = xTrain(:,i_b)';
   %     b(end,:) = uNew(i_new,:);
   
    %% Hyperparameter update
    %
    if mod(jj,100) == 0
    i_f = jj-windowSize:jj;
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
    
    pred(iter:iter+windowSize) = mu_s';  % Store prediction
    vari(iter:iter+windowSize) = var_s';
    
    yTest(iter:iter+windowSize)  = yTrue;      % Store True values
    iTest(iter:iter+windowSize)  = i_sNew;
    
    %iter = iter + 1;
    iter = iter + windowSize;
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
resultsIFITC = figure(4);clf(resultsIFITC);
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
han(1) = scatter(T(1,i_loop),yloop(:,1),'xb');
han(3) = plot(iTest*Ts,pred,'r','LineWidth',1.5);
%scatter(u(:,1),zeros(Mu,1))
han(4) = plot(iTest*Ts,pred + (vari+sn^2),'k');
plot(iTest*Ts,pred - (vari+sn^2),'k');
legend(han,'Initial data','Incremental data','t+1 predictions',...
    'Predictive var.','Interpreter','Latex','FontSize',fSize);
ylabel('y','Interpreter','Latex','FontSize',fSize+4)
xlabel('t (s)','Interpreter','Latex','FontSize',fSize+4)
title('Streaming Sparse GP - Bui2017','Interpreter','Latex','FontSize',fSize+8);
hold off
clear ha han
[resultsIFITC,sphandle] = subplots(resultsIFITC,sphandle);

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