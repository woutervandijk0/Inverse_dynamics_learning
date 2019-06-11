function [X,NORM,minNorm,n,indUpdate] = lhcUpdate(xTrain,X,NORM,minNorm,n,Z,init)

[dof, N] = size(xTrain);
indUpdate = false;

%% Initialize latin hypercube
if init == 1
    X = ones(Z,1).*xTrain(1,1);
    for i = 2:dof
        X = [X,ones(Z,1).*xTrain(i,1)];
    end
    n       = 1;       %
    NORM    = -(ones(Z,Z)-eye(Z));    %Initial matrix with norms
    minNorm = 0;    % Min. norm in set of inducing points
end

%% Update latin hypercube
for sample = 1:N
    xNew = xTrain(:,sample)';
    %xNew = (xTrain(:,sample)' - mu_X) ./ sig_X; % New sample
    d_new = sqrt(sum((X-xNew).^2,2));      % Norms between new sample and inducing points
    d_min = min(d_new);                 % Minimal norm for new sample
    if (d_min > minNorm)
        d_new(n)  = 0;          % For zero on diagonal
        NORM(n,:) = d_new';     % 
        NORM(:,n) = d_new ;     % 
        X(n,:) = xNew;             % Replace inducing point with new sample
        %Find new min. norm between inducing points
        [minNorm n] = min(min(NORM+eye(Z)*1e6));    
        indUpdate = true;
    end
end

%xTrain = xTrain(:,1:10:end);
%yTrain = yTrain(:,1:10:end);

%X = X.*sig_X + mu_X;
%X = X';