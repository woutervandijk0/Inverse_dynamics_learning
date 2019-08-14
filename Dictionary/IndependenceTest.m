clc, clear all, close all
dataID = 'TFlexADRC_RN20.mat';
[xTrain, yTrain, Ts] = selectData(dataID,'fig',false);

hyp = [2.2778    0.5417    3.5655    2.2105]
sn  = 0.0939;

ts    = Ts;
T     = 3*ts;
nu    = 6.3;
N_max = 100;


numD  = 1;
D     = xTrain(3,:);
K  = SEcov(D,D,hyp);
Kinv  = 1/K;

d     = D;
k  = SEcov(D,d,hyp);
K_dd  = SEcov(d,d,hyp);

a     = Kinv\k;
delta = K_dd - k'*a;
Delta = delta;

tic;
for j = 4:1000
    d     = xTrain(j,:);
    t     = j*ts;
    
    k  = SEcov(D,d,hyp);
    K_dd  = SEcov(d,d,hyp);
    
    a     = Kinv*k;
    delta = K_dd - k'*a;
    delta
    
    if delta > nu
        if numD < N_max
            [D, K, Kinv, Delta] = insertDataPoint(D,d,hyp,K,Kinv,k,a,Delta);
            numD = numD + 1;
            T    = [T; t];
        else
            %[D, K, Kinv, delta, T] = replaceDataPoint(D, d, hyp, h, K_old, K_old_inv, k_old, a_old, delta, T, t)         
        end
    end
end
toc
%%
figure;
ha(1,1) = subplot(2,1,1)
plot(T,D)
ha(2,1) = subplot(2,1,2)
plot([3:1000]*ts,xTrain(3:1000,:))
linkaxes(ha,'x')
