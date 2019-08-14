function hyp = onlineHyperUpdate_SSGP(hyp,sn,alpha,f,yf,a,b,Saa,ma,Kaa_old)
options = optimset();
options.Display = 'none';
options.MaxIter = 10;
hyp = fminsearch(@(hyp) osgpNLML(hyp,sn,alpha,f,yf',a,b,Saa,ma,Kaa_old,yf'),hyp,options);

