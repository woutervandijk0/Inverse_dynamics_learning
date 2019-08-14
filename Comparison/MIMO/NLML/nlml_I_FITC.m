function [nlml] = nlml_I_FITC(hyp, u, f, y, infer)
sn  = abs(hyp(end));     % Signal noise
sn2 = sn.^2;        % 
hyp = abs(hyp(1:end-1));

Mu  = length(u);    
Mf  = length(f);    
Kuu = SEcov(u,u,hyp) + eye(Mu)*sn2;
Kuf = SEcov(u,f,hyp);
Kff = SEcov(f,f,hyp) + eye(Mf)*sn2;

%Equation 8
Lu  = chol(Kuu,'lower');
Luinv_Kuf = solve_lowerTriangular(Lu,Kuf);
Qff = Luinv_Kuf'*Luinv_Kuf;

switch infer
    case 'FITC'
        G = diag(Kff - Qff) + sn2;
        T = 0;
    case 'VFE'
        G = ones(1,Mf).*sn2;
        T = Kff - Qff;
end

B = Qff + diag(G);
LB = chol(B,'lower');
LB_y = solve_lowerTriangular(LB,y);


nlml = Mf/2*log(2*pi)       + ...
    1/2*sum(log(diag(LB)))  + ...
    1/2*LB_y'*LB_y          + ...
    1/(2*sn2)*trace(T);
