%Test solve_chol_sfun.mexw64

%Compile solve_lowerTriangular_sfun.c
mex -v -R2018a  solve_lowerTriangular_sfun.c -lmwlapack
mex -v -R2018a  solve_lowerTriangMatrix_sfun.c -lmwlapack


%Compile solve_linSystem_sfun.c
mex -v -R2018a  solve_linSystem_sfun.c -lmwlapack
