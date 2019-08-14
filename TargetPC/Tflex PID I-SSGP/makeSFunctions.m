%Test solve_chol_sfun.mexw64

%Compile solve_chol_sfun.c
mex -v -R2018a solve_chol_sfun.c -lmwlapack 