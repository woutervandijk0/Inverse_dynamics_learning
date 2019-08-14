t = controlOutputs.time;

FB = controlOutputs.signals(1);
FF = controlOutputs.signals(2);

figure(11);clf(11);
ha(1) = plot(t,FB.values(:));
hold on
ha(2) = plot(t,FF.values(:));
legend(ha,FB.label,FF.label)


%%
t = TrainingData.time;
xTrain = TrainingData.signals(1).values;
yTrain = TrainingData.signals(2).values;

%%
[dof, N] = size(xTrain');
yTrain  = yTrain(:,1)';
xTrain  = xTrain';
xSp = xTrain;
%xSp(3,:)  = movmean(xTrain(3,:),5);

T       = [[0:N-1]*Ts];       % Time 

%% (Hyper)parameters 
%Hyperparameters 
sn  = 6;          % Noise variance
sf   = 500;           % Signal variance
l    = [ones(1,dof)];   % characteristic lengthscale
%Combine into 1 vector
hyp  = [sf,l];

%% Data selection (intial)
i_f = [1:250];
i_u = [1:5:i_f(end)];
i_s = i_f;
i_loop  = [i_f(end)+1:999];

f  = xTrain(:,i_f)';
u  = xTrain(:,i_u)';
s  = xTrain(:,i_s)';
loop   = xTrain(:,i_loop)';

yf = yTrain(:,i_f)';
ys = yTrain(:,i_s)';
yloop   = yTrain(:,i_loop)';

Mf  = length(i_f);

%% Hyperparameter optimization
fprintf('Updating hyperparameters...')
options = optimset;
options.Display = 'final';
options.MaxIter = 100;
%[nlml] = nlml_I_FITC(hyp, sn, u, f, yf, 'VFE')
[hyp_sn nlml] = fminsearch(@(hyp) nlml_I_FITC(hyp, u, f, yf, 'VFE'),[hyp,sn],options);
hyp = abs(hyp_sn(1:end-1));
sn  = abs(hyp_sn(end));
sn2 = sn^2;
%}

%% Run FITC over initial window
Ts = 1/1000;
[mu_s, var_s, mu_u, var_u, Kuu] = FITC(hyp,sn,u,f,yf,s);
figure
hold on
plot(T(1,i_f),ys)
plot(T(1,i_f),mu_s)
