%Test solve_chol_sfun.mexw64

%Compile solve_chol_sfun.c
mex -v -R2018a solve_chol_sfun.c -lmwlapack

pause(1)
%Open simulink model 
%open_system('solve_chol_sfun_test')

%Parameters: 
D = 20;                 %size
x = linspace(-4,4,D);
A = 1*exp(-(x-x').^2/2) + eye(D)*1;
B = rand(D,1);

%Add path to mex function of solve_chol
addpath('C:\Users\wout7\Documents\GitHub\Inverse_dynamics_learning\Functions\solve_chol')
sol1 = solve_chol(A,B);

%Run model
sim('solve_chol_sfun_test')
%Check result
sol2 = squeeze(simout.Data(:,1,1));
%%
fprintf('\nFrom   solve_chol.mexw64     solve_chol_sfun.mexw64 \n')
fprintf('         %.3f                  %.3f \n',[sol1,sol2])

fprintf('\nsolve_chol.mexw64:        [%.3f',sol1(1))
fprintf(', %.3f',sol1(2:10)); fprintf('] \n');

fprintf('solve_chol_solve.mexw64:  [%.3f',sol2(1))
fprintf(', %.3f',sol2(2:10));fprintf('] \n');

fprintf('B:                        [%.3f',B(1))
fprintf(', %.3f',B(2:10));fprintf('] \n');
