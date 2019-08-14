function [u,Kuu,Lu,mu_u,var_u,Mu] = updateInducing(hyp,sn,u,mu_u,var_u,Kuu,sNew,uRatio)
%UPDATEINDUCING Update the inducing points
Mu = size(u,1);
% Decide which point to remove
nRemove = floor(uRatio*Mu);
if uRatio == 1
    i_del = 1:nRemove-1;
    i_new = floor(linspace(1,size(sNew,1),nRemove-1));
elseif uRatio == 0
    i_del = 1;
    i_new = 1;
elseif uRatio > 1  %remove the first uRatio inducing points
    i_del = 1:uRatio;
    i_new = 1;
else
    i_del   = unique(randi(Mu,1,nRemove));
    i_new = sort(randi(size(loop,1),1,nRemove));    
end
nRemove = size(i_del,2);

u(i_del,:)  = [];       % Remove from inducing points
mu_u(i_del) = [];       % Remove from mean
var_u (:,i_del) = [];   % Remove from var
var_u (i_del,:) = [];   % "             "
Kuu (:,i_del) = [];     % Remove from Covariance Matrix
Kuu (i_del,:) = [];     % "             "

%Select new inducing points
u_new = sNew(i_new,:);
Kuup  = SEcov(u,u_new,hyp);
Kupup = SEcov(u_new,u_new,hyp);% + eye(nRemove)*sn^2;

%Update mu_u    (equation 3 - bijl2016)
Lu         = chol(Kuu,'lower');
Luinv_Kuup = solve_lowerTriangular(Lu,Kuup);
Luinv_mu_u = solve_lowerTriangular(Lu,mu_u);
mu_u       = [mu_u                  ; 
              Luinv_Kuup'*Luinv_mu_u];

%Update var_u   (equation 3 - bijl2016)
Luinv_var_u = solve_lowerTriangular(Lu,var_u);
var_uup     = Luinv_var_u'*Luinv_Kuup;
D           = Kuu - var_u;
Luinv_D     = solve_lowerTriangular(Lu,D);
Kuuinv_Kuup = solve_linSystem(Kuu,Kuup);
var_upup    = Kupup - Luinv_Kuup'*Luinv_D*Kuuinv_Kuup;
var_u       = [var_u   , var_uup ;
               var_uup', var_upup];
           
% New vector of ind. point + recalculate some stuff
u   = [u;u_new];
Mu  = Mu - length(i_del) + length(i_new);
Kuu = SEcov(u,u,hyp) + eye(Mu)*sn^2;
Lu  = chol(Kuu,'lower');
end

