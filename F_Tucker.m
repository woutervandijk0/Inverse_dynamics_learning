clc, clear all

%% Load dataset
dataID = 'sarcos_inv.mat';
[xTrain, yTrain, ts, dof] = selectData(dataID,'fig',false);
maxElem = 2000;

X = xTrain(1:maxElem,1:dof(1));             % Positions
V = xTrain(1:maxElem,dof(1)+1:2*dof(1));    % Velocities
A = xTrain(1:maxElem,2*dof(1)+1:3*dof(1));  % Accelerations
Y = yTrain(1:maxElem,1);                    % Torques

%% Normalization 
mu_X = mean(X);
mu_V = mean(V);
mu_A = mean(A);
mu_Y = mean(Y);

var_X = std(X)./100;
var_V = std(V)./100;
var_A = std(A)./100;
var_Y = std(Y)./100;

X = (X-mu_X)./var_X;
V = (V-mu_V)./var_V;
A = (A-mu_A)./var_A;
%Y = (Y-mu_Y)./var_Y;

min_X = min(X)-1;
min_V = min(V)-1;
min_A = min(A)-1;
min_Y = min(Y)-1;

X = X - min_X;
V = V - min_V;
A = A - min_A;
%Y = Y - min_Y;

X = round(X);
V = round(V);
A = round(A);
%Y = round(Y);

binX = [min(X(:)) : max(X(:))];
binV = [min(V(:)) : max(V(:))];
binA = [min(A(:)) : max(A(:))];
binY = [min(Y(:)) : max(Y(:))];

nX   = size(binX,2);
nV   = size(binV,2);
nA   = size(binA,2);
nY   = size(binY,2);

[nX nV nA ]

%% Create Tensor
n     = length(X);          % Reduct to the first n points
T     = zeros(nX,nV,nA);    %
% Sparse version
subs  = [X(:,1),V(:,1),A(:,1)]; 
vals  = Y(:,1);
Tsp   = sptensor(subs,vals);

for i = 1:n
    indx    = [X(i,1),V(i,1),A(i,1)];
    T(indx) = Y(i,1);
end


TT = tucker_als(Tsp,10);
G = TT.core;
A = TT.U{1};
B = TT.U{2};
C = TT.U{3};


%%
Y_appr = full(TT);
E = Y_appr - Tsp;

%% Tensor decomposition

%% Prediction????