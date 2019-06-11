clear all, clc
fromData
fig2pdf = 0;
pdf2ipe = 0;
param_update   =  false;  % Update hyperparameters in the loop (true/false)

%% Load dataset:
dataID = 'TFlexADRC_RN20.mat';
%dataID = 'TFlex1D5G.mat';
dataID = 'TFlex1D-2.mat';
[xTrain, yTrain, ts] = selectData(dataID,'fig',false);
xTrain = xTrain(250/ts:end,:);
yTrain = yTrain(250/ts:end,:);
xTrain = xTrain';
yTrain = yTrain';
[dof, N] = size(xTrain);

%xSetpoint = loadSp(dataID)';

%Normalize data
mu_X  = mean(xTrain');
sig_X = std(xTrain');
xTrain = ((xTrain' - mu_X) ./ sig_X)';
mu_Y  = mean(yTrain');
sig_Y = std(yTrain');
yTrain = ((yTrain' - mu_Y) ./ sig_Y)';

%% (Hyper)parameters 
l = ones(1,dof)*0.01;        % characteristic lengthscale
sf = 0.01;               % Signal variance

% Dataset Sil
l  = [13.8997   22.6550    4.1100];
sf = 0.9301

% TFlex1D-2.mat
l  = [114.9646  310.7584  220.8015];
sf = 0.0589

%sn = 33/sig_Y
sn = 6.4/sig_Y;       % Noise variance
%sn = 1/sig_Y;       % Noise variance
hyp = [sf,l];
beta = 0.1
optRatio = 500;     % Do a hyperparam update every 500th iteration

batchSize = 5;  %
Z      = 25;    % Number of inducing points
M      = 50;    % Size of floating window
M_hyp  = 150;   % Size of floating window for hyperparam update
decay  = 0.999;     % Decay factor for inducing points
jitter = 1e-5;  % For numerical stability
alpha  = 0.5;     % VFE,  alpha = 0
                % SPEP, 0 < alpha < 1
                % FITC, alpha = 1
maxIter = 1e5;

% Empty vector for results
%mu = zeros(1,2000);
%s2pr = zeros(1,2000);
numIter = min(N-batchSize,maxIter);
MU = zeros(N,1);
HYP = zeros(round(numIter/optRatio),4);
HYP(1,:) = hyp;

%% Initialize Streaming sparse GP algorithm

% Inducing points
NORM = zeros(Z,Z);          % Matrix containing norm between inducing points
n    = 0;   minNorm = 0;    % Index of minNorm;   Minimum Norm
b    = zeros(dof,Z);        % Inducing points

% Create initial set of inducing points
%xInit = ((xTrain(:,1)' - mu_X) ./ sig_X)';
[b,NORM,minNorm,n] = lhcUpdate(xTrain(:,1),b,NORM,minNorm,n,Z,1);

% Fminsearch settings
options = optimset;
options.Display     = 'off';%'iter-detailed';
options.MaxIter     = 20;
%[ active-set | interior-point | interior-point-convex | levenberg-marquardt | ...
%                          sqp | trust-region-dogleg | trust-region-reflective ]
%options.Algorithm   = 'interior-point';

%% Inital step (ISGP)
f   = xTrain(:,1:M)';    % Training points
yf  = yTrain(1,1:M);     %
err = yf;                %
p   = xTrain(:,M+1)';    % Query point

% Update inducing points
[b,NORM,minNorm,n] = lhcUpdate(f',b,NORM,minNorm,n,Z,0);

% Add inducing points to test points
s = [b;p];

% Some lengths
Mb = length(b);
Ma = Mb;
Mf = length(f);
Ms = length(s);

% Optimize hyperparameters
%[hyp_new nlml] = fmincon(@(hyp) sgpNLML(hyp,sn,alpha,f,yf,b,s,err,Mf),hyp,[],[],[],[],[0,0,0,0],[],[],options);
%hyp = (1-beta)*hyp + beta*hyp_new;
HYP(2,:) = hyp;

% Build common terms
[LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs, Dff, LD, ~] = sgpBuildTerms(hyp,sn,f,yf,b,s,alpha);

%Predictive mean
m = LDinv_Lbinv_Kbs'*LDinv_c;

%Prediction variance (matrix)
Kss  = SEcov(s,s,hyp) + eye(Ms)*jitter;
var1 = Kss;
var2 = -Lbinv_Kbs'*Lbinv_Kbs;
var3 = LDinv_Lbinv_Kbs'*LDinv_Lbinv_Kbs;
Su   = var1 + var2 + var3;

%Prediction variance (vector)
var  = diag(Su);

% Seperate predictions at inducing points from other points
Saa = Su(1:Mb,1:Mb);
ma  = m(1:Mb);
Kaa_old = Saa;

% Precictions at query point
s2pr(M+1) = var(end);
mu(M+1) = m(end);

figure(5);
plot(b(:,1),ma,'x')
hold on
plot(f(:,1),yf,'o')
plot(p(:,1),mu,'x')
ylim([-4 4])

%hyp = hyp_copy;
options.MaxIter = 20;
tic;
%% Start loop (OSGP)
iter_hyp = 3;
numIter = min(N-batchSize,maxIter);
for iter = M_hyp+1:batchSize:numIter
    iActive = (iter+batchSize-1);
    % Acces new data point
    xNew = xTrain(:,iter:iActive);
    yNew = yTrain(:,(iter:iActive));
    
    % Update active set
    f   = [f(batchSize+1:end,:); xNew'];
    yf  = [yf(batchSize+1:end),yNew];
    err = yf;
    p   = xTrain(:,iActive+1:(iActive+batchSize))';    % New test point
    %yp  = yTrain(:,iActive+1:(iActive+batchSize))';
    %p   = xSetpoint(:,iActive+1:(iActive+batchSize))';
        
    % Update inducing points
    a = b;
    [b,NORM,minNorm,n,indUpdate] = lhcUpdate(xNew,b,NORM,minNorm,n,Z,0);
    NORM = NORM*decay;
    % Add inducing points to test points
    s = [b;p];
    Ms = length(s);
    
    %if indUpdate == true || iter == M+1
        Kaa_old = SEcov(a,a,hyp);
    %end
    if param_update == true
        %Hyperparameter optimalisation
        if (iter == M+1 || mod(iter-(M+1),optRatio)==0)
            f2  = xTrain(:,(iter-M_hyp):iter);
            yf2 = yTrain(:,(iter-M_hyp):iter);
            [hyp_new nlml]  = fmincon(@(hyp) osgpNLML(hyp,sn,alpha,f,yf,a,b,Saa,ma,Kaa_old,err),hyp,[],[],[],[],[0,0,0,0],[1,inf,inf,inf],[],options);
            hyp = (1-beta)*hyp + beta*hyp_new;
        end
    end
    HYP(iter_hyp,:) = hyp;
    iter_hyp    = iter_hyp + 1;
    
    % Build common terms
    [La, Lb, LD, LSa, LDinv_c, Dff, Sainv_ma, LM, Q, LQ] = osgpBuildTerms(hyp,sn,f,yf,a,b,Saa,ma,Kaa_old,alpha);
    Kbs = SEcov(b,s,hyp);
    Lbinv_Kbs       = solve_lowerTriangular(Lb, Kbs);
    LDinv_Lbinv_Kbs = solve_lowerTriangular(LD, Lbinv_Kbs);
    
    %Predictive mean
    m = LDinv_Lbinv_Kbs'*LDinv_c;
    
    %Prediction variance (matrix)
    Kss = SEcov(s,s,hyp) + eye(Ms)*jitter;
    var1 = Kss;
    var2 = -Lbinv_Kbs'*Lbinv_Kbs;
    var3 = LDinv_Lbinv_Kbs'*LDinv_Lbinv_Kbs;
    Su  = var1 + var2 + var3;
    
    %Prediction variance (vector)
    var = diag(Su);
    
    % Seperate predictions at inducing points from other points
    Saa = Su(1:Mb,1:Mb);
    ma  = m(1:Mb);
    Kaa_old = Saa;
    
    % Precictions at query point
    s2pr = var(Mb+1:end);
    mu   = m(Mb+1:end);
    MU(iActive+1:(iActive+batchSize),1) = mu;
    
    %Plot results
%     clf(5)
%     plot(f(:,1),yf,'o')
%     drawnow
    %{
    clf(5)
    hold on
    plot(b(:,1),ma,'x')
    plot(f(:,1),yf,'o')
    plot(p(:,1),mu,'x')
    ylim([-4 4])
    xlim([-26 26])
    hold off
    drawnow
    %}
    
    % show progress
    if mod(iter-1,round((numIter)/10)) == 0
        disp([num2str(round((iter-batchSize)/numIter*100)),' %'])
    end
    options.MaxIter = 5;
    
end
toc;
t_run = toc/size(M_hyp+1:batchSize:numIter,2);
fprintf(['Elapsed time per iteration: ',num2str(t_run/1e-3),' ms\n'])
%%
%yTrain = ((yTrain' - mu_Y) ./ sig_Y)';
yTrain  = yTrain.*sig_Y + mu_Y;
xTrain  = xTrain'.*sig_X + mu_X;
xTrain =  xTrain'
b = b.*sig_X + mu_X;

MU = MU.*sig_Y + mu_Y;
%% Show results
t = [iter:iActive]*ts;
%Predictions
fig6 = figure(6);clf(6);
han6(1,1) = subplot(2,1,1);
hold on
plot([1:length(yTrain)]*ts,yTrain)
plot([1:length(MU)]*ts,MU)
plot(t,yNew,'x')
ylabel('Current (mA)')
hold off

han6(2,1) = subplot(2,1,2);
plot(linspace(0,t(end),length(HYP)),HYP)
ylabel('Hyperparameters')
xlabel('t (s)')
legend('$\sigma_f$','$l_1$','$l_2$','$l_3$','Interpreter','Latex')

[fig6,han6] = subplots(fig6,han6);


% Inducing points
figure(3),clf(3)
grid on
dofs = [1,2,3];
%xTrain = xTrain';
b = b';
for jj = 1:(dof/3)
subplot(1,dof/3,jj)
hold on
plot3(xTrain(dofs(1),1:5:end),xTrain(dofs(2),1:5:end),xTrain(dofs(3),1:5:end),'x');
scatter3(b(dofs(1),:),b(dofs(2),:),b(dofs(3),:),'or','filled');
view(-30,30)
hold off
dofs = dofs+1;
end
%xTrain = xTrain';
b = b';

figure(7),clf(7)
plot(xTrain(1,:),yTrain)
hold on
plot(xTrain(1,:),MU)
hold off
%[results,sphandle] = subplots(results,sphandle,'gabSize',[0,0.02]);

%% Error
tStart = 12;
predict = MU(tStart/ts:end);
yCheck = yTrain(tStart/ts:end);

ii = find(predict~=predict(end));
t = ii*ts;
predict = predict(ii)';
yCheck  = yCheck(ii);
nn = length(predict);

disp(' ');
disp(['t+1 predictions (from measurements):']);
%NMSE = errorMeasure(predict,yCheck,'method','NMSE','show',true);
%MAE = errorMeasure(predict,yCheck,'method','MAE','show',true);
%MSE = errorMeasure(predict,yCheck,'method','MSE','show',true);
RMSE = errorMeasure(predict,yCheck,'method','RMSE','show',true);

figure(111),clf(111)
hold on
plot(t,yCheck)
plot(t,predict)
legend('Measured','Fit')
xlabel('time (s)')
ylabel('Current (mA)')
hold off
%% Save Figures
if(fig2pdf)
    saveas(results,fullfile(pwd,'Images','StreamSGP.pdf'));
end

%% PDF2IPE
if(pdf2ipe)
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''});
end

%}
%[hyp_opt;hyp_st]