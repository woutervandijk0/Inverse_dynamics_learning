clc, clear all, close all

%Compile s-functions
compile

pause(1)
%Open simulink model 
%open_system('solve_chol_sfun_test')

%Parameters: 
D = 20;                 %size
x = linspace(-4,4,D);
A = 1*exp(-(x-x').^2/2) + eye(D)*1;
B = rand(D,D);

%Add path to mex function of solve_chol
%addpath('C:\Users\wout7\Documents\GitHub\Inverse_dynamics_learning\Functions\SSGP\mex_functions\')
lowtriang = dsp.LowerTriangularSolver;
sol1 = lowtriang(A,B);

%Run model
sim('solve_lowerTriangMatrix_sfun_test')
%Check result
sol2 = squeeze(simout.Data(:,1,1));
%%

 fprintf('\nsolve_chol.mexw64:        [%.3f',sol1(1))
 fprintf(', %.3f',sol1(2:10)); fprintf('] \n');

fprintf('solve_chol_sfun.mexw64:  [%.3f',sol2(1))
fprintf(', %.3f',sol2(2:10));fprintf('] \n');

fprintf('B:                        [%.3f',B(1))
fprintf(', %.3f',B(2:10));fprintf('] \n');

