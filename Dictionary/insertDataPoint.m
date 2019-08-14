function [D, K, Kinv, Delta] = insertDataPoint(D, d, hyp, K_old, K_old_inv, k_old, a_old, Delta)

%New K


%New D
m = size(D,1);
D = [D;d];

D_i   = D([1:m],:);
K_mp  = SEcov(D_i,d,hyp);
k_imp = SEcov(d,d,hyp);
k_mp  = SEcov(d,d,hyp);

alpha = K_old_inv*K_mp;
gamma = k_mp + alpha'*K_mp;
a_new = (1./gamma).*[gamma*a_old + alpha*alpha'*k_old - k_imp*alpha; -alpha'*k_old + k_imp];
deltaTerm = [k_old;k_imp]'*a_new;
for i = 1:m
    k_dd  = SEcov(D(i,:),D(i,:),hyp);
    
    Delta(i,1) = k_dd - deltaTerm;
    
%     %Equation 7
%     Kinv = (1./gamma).* [gamma*K_old_inv + alpha*alpha' , -alpha;
%         -alpha' , 1];
end
%Equation 7
Kinv = (1./gamma).* [gamma*K_old_inv + alpha*alpha' , -alpha;
-alpha' , 1];
    K = [K_old, K_mp; K_mp', k_mp];

end