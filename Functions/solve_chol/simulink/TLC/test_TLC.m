% Test solve_chol_sfun.mexw64
% 

% Compile solve_chol_sfun.c
mex -v -R2018a solve_chol_sfun.c -lmwlapack

% Model name
model   = 'solve_chol_sfun_test_TLC';     % Simulink model
File    = fullfile(cd, 'test.mat');        % Result file of simulation

% Delete old files to make sure we don't run an old model
if exist('test.mat') ~= 0 
    delete(File);
    fprintf('test.mat deleted...\n')
    fprintf('solve_chol_sfun_test_TLC.mat deleted...\n')
end
if exist('solve_chol_sfun_test_TLC.mat') ~= 0
    delete(fullfile(cd, 'solve_chol_sfun_test_TLC.mat'));
    fprintf('solve_chol_sfun_test_TLC.mat deleted...\n')
end
if exist([model,'.exe']) ~= 0
    delete(fullfile(cd,[model,'.exe']));
    fprintf([model,'.exe deleted...\n'])
end

%Parameters: 
D = 25;                 % Number of features 
x = linspace(-4,4,D);   %
A = 1*exp(-(x-x').^2/2) + eye(D)*1; %Positive semidefinite matrix
B = rand(D,1);          %

% Run model (normal mode)
sim(model)              % Simulation in normal mode
load('test.mat');        
sol_normal = out(2:end,2);      % Store Data
delete(File);           % Remove file

% Run model (external mode)
rtwbuild(model)         % Compile the model to an .exe file
pause(1)
system('solve_chol_sfun_test_TLC.exe -flag1 A -flag2 B');
pause(1)
load('test.mat')
sol_compiled = out(2:end,2);
%% Compare results
%Add path to mex function of solve_chol
check = solve_chol(A,B);
fprintf('Compare results: \n')
fprintf('solve_chol.mexw64:        [%.3f',check(1))
fprintf(', %.3f',check(2:10)); fprintf('] \n');

fprintf('solve_chol_solve.mexw64:  [%.3f',sol_normal(1))
fprintf(', %.3f',sol_normal(2:10));fprintf('] \n');

fprintf('solve_chol_solve.tlc:     [%.3f',sol_compiled(1))
fprintf(', %.3f',sol_compiled(2:10));fprintf('] \n');

