%clear all, %close all

%{
%Hyperparameters 
l = 0.1;        % characteristic lengthscale
sf = 1;         % Signal variance
sn  = 0.1;       % Noise variance
hyp_opt = [sf,l];

jitter = 1e-12; % For numerical stability
alpha = 0.5;    % VFE,  alpha = 0
                % SPEP, 0 < alpha < 1
                % FITC, alpha = 1
                
%% Create training data (random draw from GP):
numSamples = 50001;
t  = linspace(0,50,numSamples);           % Input
xTrain(1,:)  = sin(t) + (rand(1,numSamples)-1/2).*0.1;
xTrain(2,:)  = cos(t);
%xTrain(3,:)  = cos(t) - (rand(1,numSamples)-1/2).*0.1;
%xTrain(4,:)  = t;
%xTrain  = [xTrain;sin(xTrain);cos(xTrain)];
%KK      = SEcov(xTrain',xTrain',hyp_opt);   % SE covariance kernel

yTrue   = cos(xTrain(1,:)).*tanh(xTrain(1,:)) + sin(xTrain(1,:)) - xTrain(1,:);
%yTrue   = KK*randX;                     % Underlying function
yTrain  = yTrue + randn(1,numSamples)*sn;     % Add noise
%}

dataID = 'BaxterRhythmic.mat';
[xTrain, yTrain, ts] = selectData(dataID,'fig',false);
N      = length(xTrain);
xTrain = xTrain(:,:)';
yTrain = yTrain';

%% test inducing point selection
Z   = 100;                 %Number of inducing points
dof = size(xTrain,1);                

%% Normalisation
mu_X  = mean(xTrain');
sig_X = std(xTrain');

%% Update inducing points
NORM = zeros(Z,Z);
minNorm = 0;
init = 1;
X = zeros(dof,Z);
n = 0;
x = (xTrain' - mu_X) ./ sig_X;
%{
X = ones(Z,1).*x(1);
for i = 2:dof
    X = [X,ones(Z,1).*x(i)];
end
n       = 1;       % 
NORM    = -(ones(Z,Z)-eye(Z));    %Initial matrix with norms
minNorm = 0;    % Min. norm in set of inducing points

for sample = 2:N
    x = (xTrain(:,sample)' - mu_X) ./ sig_X; % New sample
    d_new = sqrt(sum((X-x).^2,2));      % Norms between new sample and inducing points
    d_min = min(d_new);                 % Minimal norm for new sample
    if (d_min > minNorm)
        d_new(n)  = 0;          % For zero on diagonal
        NORM(n,:) = d_new';     % 
        NORM(:,n) = d_new ;     % 
        X(n,:) = x;             % Replace inducing point with new sample
        %Find new min. norm between inducing points
        [minNorm n] = min(min(NORM+eye(Z)*1e6));    
    end
end
xTrain = xTrain(:,1:10:end);
yTrain = yTrain(:,1:10:end);
%}
[X,NORM,minNorm,n] = lhcUpdate(x',X,NORM,minNorm,n,Z,init);
X = X.*sig_X + mu_X;
X = X';

%% Show results
%{
fig2 = figure(2); clf(fig2)
set(gcf,'Color','White')
grid on
dofs = [1,8,15];
for jj = 1:2%(dof/3)
%subplot(1,dof/3,jj)
subplot(1,2,jj)
hold on
plot3(xTrain(dofs(1),:),xTrain(dofs(2),:),xTrain(dofs(3),:),'x');
scatter3(X(dofs(1),:),X(dofs(2),:),X(dofs(3),:),'or','filled');
view(-30,30)
xlabel('$x$','Interpreter','Latex','fontSize',15)
ylabel('$\dot{x}$','Interpreter','Latex','fontSize',15)
zlabel('$\ddot{x}$','Interpreter','Latex','fontSize',15)
title(['Link ',num2str(jj)])
grid on
hold off
dofs = dofs+1;
end

fig2pdf = 1;
pdf2ipe = 1;

% Save Figures
if(fig2pdf)
    saveas(fig2,fullfile(pwd,'Images','LatinHyperCube.pdf'));
end

% PDF2IPE
if(pdf2ipe)
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''});
end
%}
%% Test speed lower triangular solver 

% Call to a linear system solver
lowtriang = dsp.LowerTriangularSolver;
lowtriang.release();

tic
for i = 1:10000
    Lbinv_Kbs = lowtriang(Lb, Kbs);
    lowtriang.release();
end
tLowtriang = toc
ansLowtriang = Lbinv_Kbs;

tic
for i = 1:10000
    Lbinv_Kbs = solve_lowerTriangular(Lb, Kbs);
end
tMexfunc = toc
ansMexfunc = Lbinv_Kbs;
ansDiff = mean(mean(ansLowtriang-ansMexfunc))

speedup = tLowtriang/tMexfunc

%% 
A = rand(25); b = rand(25,1);
C = b;
tic;
for i = 1:100000
    C = A\b;
end
tBasic = toc;
ansBasic = C;

tic;
for i = 1:100000
    C = solve_linSystem(A,b);
end
tMex = toc;
ansMex = C;

tBasic/tMex

%%
%Parameters: 
D = 100;                 %size
x = linspace(-4,4,D);
A = 1*exp(-(x-x').^2/2) + eye(D)*1;
B = rand(D,1);

LA = chol(A,'lower');

tic;
for i = 1:10000
x = (LA\(LA'\B));
end
tBasic = toc;

tic;
for i = 1:10000
x = solve_chol(LA,B);
end
tMex = toc;

tBasic/tMex

%}
