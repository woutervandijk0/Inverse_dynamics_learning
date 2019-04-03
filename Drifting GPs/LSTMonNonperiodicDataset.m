clear all, close all
addpath('Plot_tools')
addpath('Functions')

%% Select and open Dataset ('Default' opens file explorer)
dataID = 'TFlex1D.mat';
dataID = 'BaxterRand.mat';
%dataID = 'TFlex1D5G.mat';


[X,Y,ts,N_io] = selectData('dataset',dataID);

%% Resampling
resamp = 1;
X = X(1:resamp:end,:);
Y = Y(1:resamp:end,1);

%% Select training data and standardize
fact = 0.1
XTrain = X(1:round(end*fact),:);
XTest  = X((round(end*fact)+1):end,:);
YTrain = Y(1:round(end*fact),:);
YTest  = Y((round(end*fact)+1):end,:);

figure;
plot(YTrain)

mu_X = mean(XTrain);
sig_X = std(XTrain);
XTrainStandardized = (XTrain - mu_X) ./ sig_X;

mu_Y = mean(YTrain);
sig_Y = std(YTrain);
YTrainStandardized = (YTrain - mu_Y)./ sig_Y;

XTrain = XTrainStandardized(1:end-1,:)';
%YTrain = YTrainStandardized(2:end,:)';
YTrain = YTrain(2:end,:)';

%% Define LSTM network
numFeatures  = size(XTrain,1);
numResponses = size(YTrain,1);
numHiddenUnits = 100;

layers = [ ...
    sequenceInputLayer(numFeatures)
    lstmLayer(numHiddenUnits,'OutputMode','sequence')
    lstmLayer(numHiddenUnits,'OutputMode','sequence')
    lstmLayer(numHiddenUnits,'OutputMode','sequence')
    fullyConnectedLayer(numResponses)
    regressionLayer];

options = trainingOptions('adam', ...
    'MaxEpochs',100, ...
    'GradientThreshold',1, ...
    'InitialLearnRate',0.005, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropPeriod',50, ...
    'LearnRateDropFactor',0.2, ...
    'Verbose',0, ...
    'Plots','training-progress');

%% Training
net = trainNetwork(XTrain,YTrain,layers,options);

%% Forecasting and update
XTestStandardized = (XTest - mu_X) ./ sig_X;
XTest = XTestStandardized(1:end-1,:)';

tic
lenTrain = length(XTrain);
net = predictAndUpdateState(net,XTrain);
[net,YPred] = predictAndUpdateState(net,XTrain(:,lenTrain));

numTimeStepsTest = length(XTest);
for i = 2:numTimeStepsTest
    [net,YPred(:,i)] = predictAndUpdateState(net,XTest(:,i-1),'ExecutionEnvironment','cpu');
end
toc
%%
%YPred = sig_Y.*YPred' + mu_Y;

%rmse = sqrt(mean((YPred-YTest).^2));

%%

figure(222),clf(222)
hold on
plot(YTest)
plot(YPred','-xr')
hold off