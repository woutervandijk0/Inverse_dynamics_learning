%Script that writes simulation settings to 'settings' struct

settings.dataID     =   dataID;
settings.X_active   =   X_active;
settings.resamp     =   resamp;
settings.maxSamples =   maxSamples;
settings.ts         =   ts;
settings.batchSize  =   batchSize;
settings.TS         =   TS;

settings.param_update = param_update;
settings.param_fix    = param_fix;
showAnimation         = showAnimation;

settings.cov        =   cov;
settings.mean_gp    =   mean_gp;
settings.lik        =   lik;
settings.inf        =   inf;
settings.hypStruc  	=   hypStruc;
settings.N_search  	=   N_search;
settings.s          =   s;

settings.N          =   N;
settings.Q          =   Q;
settings.P          =   P;
settings.Z          =   Z;
settings.M          =   M;
settings.N_query    =   N_query;

settings.ts         =   ts;
settings.TS         =   TS;

settings.alpha      =   alpha;
settings.beta       =   beta;
settings.kappa      =   kappa;
settings.method     =   method;
settings.timestamp  =   datetime('now');