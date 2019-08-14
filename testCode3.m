clc, clear all, close all

ts = 1/1000;
t0 = 0;
T  = 20;

alpha_T = 0.0001;
alpha_0 = 1;

beta_0 = nthroot(alpha_T/alpha_0,(T-t0)/ts)