%clear all, clc
fig2pdf = 0;
pdf2ipe = 0;

%% Load dataset:
%dataID = 'TFlexADRC_RN20.mat';
%[xTrain, yTrain, ts] = selectData(dataID,'fig',false);
xTrain = xTrain(:,:)';
yTrain = yTrain';
[dof, N] = size(xTrain);

mu_X  = mean(xTrain');
sig_X = std(xTrain');
xTrain = ((xTrain' - mu_X) ./ sig_X)';

%% Hyperparameters 
l = ones(1,dof)*0.1;        % characteristic lengthscale
%l = [0.3458    0.3781    0.5866];
sf = 100;         % Signal variance
sn  = 3.1;       % Noise variance
hyp_opt = [sf,l];
    

jitter = 1e-5;  % For numerical stability
alpha = 1;      % VFE,  alpha = 0
                % SPEP, 0 < alpha < 1
                % FITC, alpha = 1
%{ 
% Create training data (random draw from GP):
xTrain  = linspace(0,20,5000);           % Input
%xTrain  = [xTrain;sin(xTrain);cos(xTrain)];
KK      = SEcov(xTrain',xTrain',hyp_opt);   % SE covariance kernel
randX   = rand(5000,1)-1/2;             % Random vector
yTrue   = KK*randX;                     % Underlying function

ts = 0.0020;
t = [0:ts:(10-ts)]';
xTrain  = cos(t*2*pi*2)';
%xTrain  = [t'; xTrain];
yTrue   = 2*sin(t*2*pi*2);
yTrain  = yTrue + randn((t(end)+ts)/ts,1)*sn;     % Add noise
%}


hyp = hyp_opt;
%hyp = abs(randn(1,2))*1
hyp_st(1,:) = hyp;
%% (Offline) Streaming Sparse Gaussian Process (initial step)
i_f = 1:2000;
i_s = [1:2000];

f  = xTrain(:,i_f)';     % Training points
%a  = xTrain(i_a)';      % Old inducing points
%b  = xTrain(:,i_b)';     % New inducing points
s  = xTrain(:,i_s)';     % Test points


Z       = 100;
NORM    = zeros(Z,Z);
minNorm = 0;  n = 0;
b       = zeros(dof,Z);

%x = (f - mu_X) ./ sig_X;
[b,NORM,minNorm,n] = lhcUpdate(f',b,NORM,minNorm,n,Z,1);
%b = (B.*sig_X + mu_X);
%b = B

%ya = yTrain(1,i_b)';
%yb = yTrain(1,i_b)';    
yf = yTrain(1,i_f);
ys = yTrain(1,i_s);
err = yf;

%Ma = length(a);
Mb = length(b);
Mf = length(f);
Ms = length(s);

lowtriang   = dsp.LowerTriangularSolver;
lowtriang.release();

%% Approximate log marginal Likelihood
nlml(1) = sgpNLML(hyp,sn,alpha,f,yf,b,s,err,Mf);
options = optimset;
options.Display = 'iter-detailed';
options.MaxIter = 20;
Kaa_old = SEcov(b,b,hyp);

[hyp nlml(2)] = fminsearch(@(hyp) sgpNLML(hyp,sn,alpha,f,yf,b,s,err,Mf),hyp,options);
hyp_st(2,:) = hyp;


%% Prediction 
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

%%
[LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs, Dff, LD, ~] = sgpBuildTerms(hyp,sn,f,yf,b,b,alpha);

%Predictive mean
ma = LDinv_Lbinv_Kbs'*LDinv_c;

%Prediction variance (matrix)
Kss  = SEcov(b,b,hyp) + eye(Mb)*jitter;
var1 = Kss;
var2 = -Lbinv_Kbs'*Lbinv_Kbs;
var3 = LDinv_Lbinv_Kbs'*LDinv_Lbinv_Kbs;
Saa   = var1 + var2 + var3;
%Prediction variance (vector)
%var  = diag(Su);

%{
%Again but at inducing points
[LDinv_Lbinv_Kbs, LDinv_c, Lbinv_Kbs, Dff, LD, ~] = sgpBuildTerms(hyp,sn,f,yf,b,b,alpha);

%Predictive mean
ma = LDinv_Lbinv_Kbs'*LDinv_c;

%Prediction variance (matrix)
Kbb  = SEcov(b,b,hyp) + eye(Mb)*jitter;
var1 = Kbb;
var2 = -Lbinv_Kbs'*Lbinv_Kbs;
var3 = LDinv_Lbinv_Kbs'*LDinv_Lbinv_Kbs;
Saa   = var1 + var2 + var3;
%Kaa_old = Kbb;
%}

%% Plot result 
results = figure(2); clf(2);
sphandle(1,1) = subplot(3,1,1);
hold on
ha(2) = scatter(f(:,1),yf,'xb');
ha(2).MarkerFaceAlpha = .6;
ha(2).MarkerEdgeAlpha = .6;
%ha(3) = scatter(b(:,1),yb,'ok','filled');
ha(3) = scatter(b(:,1),zeros(size(b,1),1),ones(size(b,1),1)*10,'ok','filled');
%ha(1) = plot(xTrain(1,:),yTrain(1,:),'k','LineWidth',1.5);
ha(4) = plot(s(:,1),m,'-r','LineWidth',1);
ha(5) = plot(s(:,1),m + 2*sqrt(var),'-k');
ha(5) = plot(s(:,1),m - 2*sqrt(var),'-k');
%xlim([0,4]);
ylabel('y');
title('Streaming Sparse GP - Bui2017');
%legend(ha,'True function','Data in window','Inducing points','Predicted mean','Predictive var.');
hold off

sphandle(2,1) = subplot(3,1,2);
hold on
han(3) = scatter(f(:,1),yf,'xk');
han(3).MarkerFaceAlpha = .5; 
han(3).MarkerEdgeAlpha = .5;
hold off

sphandle(3,1) = subplot(3,1,3);
hold on
han(3) = scatter(f(:,1),yf,'xk');
han(3).MarkerFaceAlpha = .5; 
han(3).MarkerEdgeAlpha = .5;
hold off

%% Online Streaming Sparse Gaussian Process
i_f = 2000:4000;
i_s = [2000:4000];

f   = xTrain(:,i_f)';     % Training points
s   = xTrain(:,i_s)';     % Test points
a   = b;
yf  = yTrain(1,i_f);
ys  = yTrain(1,i_s);
err = yf;


[b,NORM,minNorm,n] = lhcUpdate(f',b,NORM,minNorm,n,Z,0);
%{
M       = length(a);
M_old   = floor(0.7*M);
M_new   = M - M_old;
old_Z   = b(randi(M,1,M_old),:);
new_Z   = f(randi(size(f,1),1,M_new),:);
b       = [old_Z;new_Z];
%}

Ma = length(a);
Mb = length(b);
Mf = length(f);
Ms = length(s);

%Saa = Su;
%ma  = m;

%% Hyperparameter optimalisation
Kaa = SEcov(b,b,hyp);
Kaa_old = Kaa;
%[nlml(3)] = osgpNLML(hyp,sn,alpha,f,yf,a,b,Saa,ma,Kaa_old,err);
[hyp nlml(4)] = fminsearch(@(hyp) osgpNLML(hyp,sn,alpha,f,yf,a,b,Saa,ma,Kaa_old,err),hyp,options);
Kaa_old = Kaa;
hyp_st(3,:) = hyp;

%% Prediction
[La, Lb, LD, LSa, LDinv_c, Dff, Sainv_ma, LM, Q, LQ] = osgpBuildTerms(hyp,sn,f,yf,a,b,Saa,ma,Kaa_old,alpha);
Kbs = SEcov(b,s,hyp);
Lbinv_Kbs = lowtriang(Lb, Kbs);
lowtriang.release();
LDinv_Lbinv_Kbs = lowtriang(LD, Lbinv_Kbs);
lowtriang.release();

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

%Again but at inducing points:
Kbs = SEcov(b,b,hyp);
Lbinv_Kbs = lowtriang(Lb, Kbs);
lowtriang.release();
LDinv_Lbinv_Kbs = lowtriang(LD, Lbinv_Kbs);
lowtriang.release();

%Predictive mean
ma = LDinv_Lbinv_Kbs'*LDinv_c;

%Prediction variance (matrix)
Kss = SEcov(b,b,hyp) + eye(Mb)*jitter;
var1 = Kss;
var2 = -Lbinv_Kbs'*Lbinv_Kbs;
var3 = LDinv_Lbinv_Kbs'*LDinv_Lbinv_Kbs;
Saa  = var1 + var2 + var3;

%% Plot results
results;
sphandle(2,1) = subplot(3,1,2);
hold on
han(2) = plot(f(:,1),yf,'xb');
han(4) = scatter(b(:,1),zeros(size(b,1),1),ones(size(b,1),1)*10,'ok','filled');
%han(1) = plot(xTrain(1,:),yTrain(1,:),'k','LineWidth',1.5);
han(5) = plot(s(:,1),m,'-r','LineWidth',2);
han(6) = plot(s(:,1),m + 2*sqrt(var),'-k');
han(6) = plot(s(:,1),m - 2*sqrt(var),'-k');
%legend(han,'True function','Data in window','Data outside window',...
%    'Inducing points','Predicted mean','Predictive var.');
%xlim([0,4]);
xlabel('t (s)');
ylabel('y');
hold off

sphandle(3,1) = subplot(3,1,3);
hold on
han(3) = scatter(f(:,1),yf,'xk');
han(3).MarkerFaceAlpha = .5; 
han(3).MarkerEdgeAlpha = .5;
hold off

%% Online Streaming Sparse Gaussian Process (part II)
i_f = 4000:4600;
i_s = [4000:5000];
f   = xTrain(:,i_f)';     % Training points
s   = xTrain(:,i_s)';     % Test points
a   = b;
yf  = yTrain(1,i_f);
ys  = yTrain(1,i_s);
err = yf;

[b,NORM,minNorm,n] = lhcUpdate(f',b,NORM,minNorm,n,Z,0);

%{
M       = length(a);
M_old   = floor(0.7*M);
M_new   = M - M_old;
old_Z   = b(randi(M,1,M_old),:);
new_Z   = f(randi(size(f,1),1,M_new),:);
b       = [old_Z;new_Z];
%}

Ma = length(a);
Mb = length(b);
Mf = length(f);
Ms = length(s);

%Saa = Su;
%ma  = m;

%% Hyperparameter optimalisation
Kaa = SEcov(a,a,hyp);
%[nlml(3)] = osgpNLML(hyp,sn,alpha,f,yf,a,b,Saa,ma,Kaa_old,err);
[hyp nlml(4)] = fminsearch(@(hyp) osgpNLML(hyp,sn,alpha,f,yf,a,b,Saa,ma,Kaa_old,err),hyp,options);

hyp_st(4,:) = hyp;

%% Prediction
[La, Lb, LD, LSa, LDinv_c, Dff, Sainv_ma, LM, Q, LQ] = osgpBuildTerms(hyp,sn,f,yf,a,b,Saa,ma,Kaa_old,alpha);
Kbs = SEcov(b,s,hyp);
Lbinv_Kbs = lowtriang(Lb, Kbs);
lowtriang.release();
LDinv_Lbinv_Kbs = lowtriang(LD, Lbinv_Kbs);
lowtriang.release();

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
Kaa_old = Kaa;

%% Plot results
results;
sphandle(3,1) = subplot(3,1,3);
hold on
plot(s(:,1),ys,'xy')
han(2) = plot(f(:,1),yf,'xb');
han(4) = scatter(b(:,1),zeros(size(b,1),1),ones(size(b,1),1)*10,'ok','filled');
%han(1) = plot(xTrain(1,:),yTrue,'k','LineWidth',1.5);
han(5) = plot(s(:,1),m,'-r','LineWidth',2);
han(6) = plot(s(:,1),m + 2*sqrt(var),'-k');
han(6) = plot(s(:,1),m - 2*sqrt(var),'-k');
%legend(han,'True function','Data in window','Data outside window',...
%    'Inducing points','Predicted mean','Predictive var.');
%xlim([0,4]);
xlabel('t (s)');
ylabel('y');
hold off

%results.PaperSize = [12.5000 9.5000]*2;
%results.Position = [-1.6318    0.8202    0.9304    0.6144]*1e3;
[results,sphandle] = subplots(results,sphandle,'gabSize',[0,0.02]);

%% Save Figures
if(fig2pdf)
    saveas(results,fullfile(pwd,'Images','StreamSGP.pdf'));
end

%% PDF2IPE
if(pdf2ipe)
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''});
end


%% Show results
figure(3),clf(3)
grid on
dofs = [1,2,3];
f = f';
b = b';
for jj = 1:(dof/3)
subplot(1,dof/3,jj)
hold on
plot3(f(dofs(1),:),f(dofs(2),:),f(dofs(3),:),'x');
scatter3(b(dofs(1),:),b(dofs(2),:),b(dofs(3),:),'or','filled');
view(-30,30)
hold off
dofs = dofs+1;
end
f = f';
b = b';
%% 
[hyp_opt;hyp_st]