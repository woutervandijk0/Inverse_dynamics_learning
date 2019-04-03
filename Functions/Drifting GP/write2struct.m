%Script that writes simulation GP to 'GP' struct

GP.dataID     =   dataID;
GP.resamp     =   resamp;
GP.maxSamples =   maxSamples;
GP.ts         =   ts;
GP.batchSize  =   batchSize;
GP.TS         =   TS;

GP.param_update = param_update;
GP.param_fix    = param_fix;
GP.showAnimation = showAnimation;
GP.loadParams = loadParams;
GP.saveParams = saveParams;

GP.cov        =   cov;
GP.cov_sp     =   cov_sp;
GP.mean_gp    =   mean_gp;
GP.lik        =   lik;
GP.inf        =   inf;
GP.HYP  	  =   HYP;
GP.N_search   =   N_search;
GP.s          =   s;

GP.N          =   N;
GP.Q          =   Q;
GP.P          =   P;
GP.Z          =   Z;
GP.M          =   M;
GP.N_query    =   N_query;

GP.ts         =   ts;
GP.TS         =   TS;

GP.alpha      =   alpha;
GP.beta       =   beta;
GP.kappa      =   kappa;
GP.method     =   method;
GP.timestamp  =   datetime('now');