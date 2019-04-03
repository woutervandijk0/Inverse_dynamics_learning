function [nlml] = calcNLML(hyp,sn2,x,y,Z,D,RAND,n)
ell   = hyp(1:n);
sf    = hyp(n+1);
sqrtD = sqrt(D);

SIGMA  = zeros(D,n);
SIGMA  = RAND.*ell;

SIGMAX = zeros(Z,D);
SIGMAX = (SIGMA*x')';
c = sf/sqrtD;
phi_x  = zeros(Z,Z);
phi_x  = c.*[cos(SIGMAX),sin(SIGMAX)];

A = phi_x'*phi_x + sn2.*speye(2*D,2*D);
%A = norm(phi_x)^2 + sn2*eye(2*D);

R_a = chol(A,'upper');
%R_a = decomposition(A,'chol');
Rt_inv_phi_y = (R_a')\(phi_x'*y);
%Rt_inv_phi_y = solve_chol(R_a',phi_x'*y);
lndetA = sum(log(diag(R_a)).^2)/2;

nlml = 1/(2*sn2)*(y'*y - Rt_inv_phi_y'*Rt_inv_phi_y) ...
    + lndetA ...
    - D/2*log(sn2) ...
    + Z/2*log(2*pi*sn2);

