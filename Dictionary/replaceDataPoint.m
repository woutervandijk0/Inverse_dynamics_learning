function [D, K, Kinv, delta, T] = replaceDataPoint(D, d, hyp, h, K_old, K_old_inv, k_old, a_old, delta, T, t) 
m = size(D,1);

lambda = exp(-(t-T).^2)./(2*h));
j = min(delta.*lambda);
D(j,:) = d;
T(j,:) = t;

for i = 1:m
    D_i   = D([1:i-1,i+1:m+1],:);
    K_mp  = SEcov(D_i,d,hyp);
    k_dd  = SEcov(D(i,:),D(i,:),hyp);
    k_imp = SEcov(d,D(i,:),hyp);
    
    r = K_mp - K_
    
end



K_mp = SEcov(D([1:j-1,j+1:end,:]),d,hyp);
k_mp = SEcov(d,d,hyp);
for i = 1:m
k_imp = 
a = 1
end