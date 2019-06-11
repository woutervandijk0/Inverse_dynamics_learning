% Test solve_chol_sfun.mexw64
% 

% Compile solve_chol_sfun.c
mex -v -R2018a solve_chol_sfun.c -lmwlapack

% Model name
if version('-release') == "2018b"
    model   = 'solve_chol_sfun_test_TLC';     % Simulink model
elseif version('-release') == "2018a"
    model   = 'solve_chol_sfun_test_TLC18a';     % Simulink model
end
File    = fullfile(cd, 'test.mat');        % Result file of simulation

fprintf('\n')
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
if exist('solve_chol_sfun_test_TLC18a.mat') ~= 0
    delete(fullfile(cd, 'solve_chol_sfun_test_TLC18a.mat'));
    fprintf('solve_chol_sfun_test_TLC18a.mat deleted...\n')
end
if exist(['solve_chol_sfun_test_TLC18a','.exe']) ~= 0
    delete(fullfile(cd,['solve_chol_sfun_test_TLC18a','.exe']));
    fprintf(['solve_chol_sfun_test_TLC18a','.exe deleted...\n'])
end
if exist(['solve_chol_sfun_test_TLC','.exe']) ~= 0
    delete(fullfile(cd,['solve_chol_sfun_test_TLC','.exe']));
    fprintf(['solve_chol_sfun_test_TLC','.exe deleted...\n'])
end
if exist('slprj')
    [status, message, messageid] = rmdir('slprj','s');
    if status == 1
        fprintf(['/slprj has been deleted...\n'])
    end
end
if exist('solve_chol_sfun_test_TLC_grt_rtw')
    [status, message, messageid] = rmdir('solve_chol_sfun_test_TLC_grt_rtw','s');
    if status == 1
        fprintf(['/solve_chol_sfun_test_TLC_grt_rtw has been deleted...\n'])
    end
end
if exist('solve_chol_sfun_test_TLC18a_grt_rtw')
    [status, message, messageid] = rmdir('solve_chol_sfun_test_TLC18a_grt_rtw','s');
    if status == 1
        fprintf(['/solve_chol_sfun_test_TLC18a_grt_rtw has been deleted...\n'])
    end
end
%% Parameters: 
D = 25;                 % Number of features 
x = linspace(-4,4,D);   %
A = 1*exp(-(x-x').^2/2) + eye(D)*1; %Positive semidefinite matrix
B = rand(D,1);          %
%% Run model (normal mode)
sim(model)              % Simulation in normal mode
load('test.mat');        
sol_normal = out(2:end,2);      % Store Data
delete(File);           % Remove file

%% Run model (external mode)
rtwbuild(model)         % Compile the model to an .exe file
pause(2)
if version('-release') == "2018b"
    system('solve_chol_sfun_test_TLC.exe -flag1 A -flag2 B');
elseif version('-release') == "2018a"
    system('solve_chol_sfun_test_TLC18a.exe -flag1 A -flag2 B');
end
pause(1)
load('test.mat')
sol_compiled = out(2:end,2);
%% Compare results
%Add path to mex function of solve_chol
check = solve_chol(A,B); %Using the matlab mex function (which is known to work)
fprintf('Compare results: \n')
fprintf('solve_chol.mexw64:        [%.3f',check(1))
fprintf(', %.3f',check(2:10)); fprintf('] \n');

fprintf('solve_chol_solve.mexw64:  [%.3f',sol_normal(1))
fprintf(', %.3f',sol_normal(2:10));fprintf('] \n');

fprintf('solve_chol_solve.tlc:     [%.3f',sol_compiled(1))
fprintf(', %.3f',sol_compiled(2:10));fprintf('] \n');

