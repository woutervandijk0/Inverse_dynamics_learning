function [ q_upd, F_upd feval ] = GoldenAlgorithm( q1, alpha, S, error, sn2,x,y,Z,D,RAND,n, feval )
% Integrated Bracketing and Golden Section Algorithm (Belegundu &
% chandrupatla p.65)
% From: Fundamental Engineering optimization methods p.131
r = 0.618034;           %Golden ratio
delta = alpha.*S';        %Stepsize;
%step 1:
q2 = q1 + delta;
F1 = calcNLML(q1,sn2,x,y,Z,D,RAND,n);
F2 = calcNLML(q2,sn2,x,y,Z,D,RAND,n);
feval = feval +2;
%step 2:
if F1<F2
    q0 = q1;
    q1 = q2;
    q2 = q0;
    delta = -delta;
end
%step 3:
delta = delta./r;
q4 = q2+delta;
F4 = calcNLML(q4,sn2,x,y,Z,D,RAND,n);
feval = feval+1;
% step 4
while F2 >= F4
    F1 = F2;
    F2 = F4;
    q1 = q2;
    q2 = q4;
    %step 3:
    delta = delta./r;
    q4 = q2+delta;
    F4 = calcNLML(q4,sn2,x,y,Z,D,RAND,n);
    feval = feval+1;
end
%step 8
q3 = q1+1;      %Start loop
while (max(abs(q1-q3)) > error) | (abs(F1-F2) > error)
    %step 5
    q3 = (1-r).*q1 + r.*q4;
    F3 = calcNLML(q3,sn2,x,y,Z,D,RAND,n);
    feval = feval+1;
    %step 6
    if F2<F3
        q4 = q1;
        q1 = q3;
    %step 7
    else
        q1 = q2;
        q2 = q3;
        F1 = F2;
        F2 = F3;
    end
end
q_upd = q2;     %Update q
F_upd = F2;     %Update F
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