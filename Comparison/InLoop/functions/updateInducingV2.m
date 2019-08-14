function [u,Kuu,Lu,mu_u,var_u] = updateInducingV2(hyp,sn,u,mu_u,var_u,Kuu,sNew,i_del)
%UPDATEINDUCING Update the inducing points

u(i_del,:)  = [];       % Remove from inducing points
mu_u(i_del) = [];       % Remove from mean
var_u (:,i_del) = [];   % Remove from var
var_u (i_del,:) = [];   % "             "
Kuu (:,i_del) = [];     % Remove from Covariance Matrix
Kuu (i_del,:) = [];     % "             "

%Select new inducing points
u_new = sNew;
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
Mu  = size(u,1);
Kuu = SEcov(u,u,hyp) + eye(Mu)*sn^2;
Lu  = chol(Kuu,'lower');
end

