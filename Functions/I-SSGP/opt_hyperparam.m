function hyp = opt_hyperparam(hyp,x,y,sn2,Z,D,RAND,n)
options = optimset();
options.Display = 'none';
options.MaxIter = 10;
hyp = fminsearch(@(hyp) calcNLML(hyp,sn2,x,y,Z,D,RAND,n),hyp,options);
