function K = SEcov(x1,x2,hyp)
%Squared exponential covariance function
n = size(x1,2);
sf = hyp(1);
l  = hyp(2:end);
%version 1
K = sf*exp(-(x1(:,1)-x2(:,1)').^2/(2*l(1)^2));
if n>1
    for i = 2:n
        K = K + sf*exp(-(x1(:,i)-x2(:,i)').^2/(2*l(i)^2));
    end
end

%version 2
%M = diag(1./(l.^2));
%K = sf.*exp(-0.5*x1*M*x2')

end