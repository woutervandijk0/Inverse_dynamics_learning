function Return = gradfunction(x,varargin)
%
% numerical computation of gradient
% this allows automatic gradient computation
% 
%
% first forward finite difference
% hstep = 0.001; - programmed in
%
hstep = 0.001;
n = length(x);
%f = feval(functname,x);
%f = nlml(hyp,sn2,x,y,Z,D,RAND,n)
%f = nlml(x,sn2,X,Y,Z,D,RAND,n)
%varargin = [sn2,X,Y,Z,D,RAND,n];
f = nlml(x,varargin{:});



for i = 1:n
   xs = x;
   xs(i) = xs(i) + hstep;
   gradx(i)= (nlml(xs,varargin{:}) -f)/hstep;
end
Return = gradx;