function [grad feval] = gradNLML(hyp,sn2,x,y,Z,D,RAND,n,feval)
%Small deviation on q
ds = 0.00001;       
hyp_d  = ones(7,7).*hyp + eye(7)*ds;

%Determine function values for all coordinates:
F0 = calcNLML(hyp,sn2,x,y,Z,D,RAND,n);
for i = 1:size(hyp_d,1)
    Fd(i,1) = calcNLML(hyp_d(i,:),sn2,x,y,Z,D,RAND,n);
end
feval = feval+1+i;    %Count function evaluations.
%Calculate gradients
grad = (Fd - F0)/ds;
end

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
end
