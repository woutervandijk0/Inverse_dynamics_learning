function [X,Y,Ninput,Ntarget] = selectData(varargin)
%SELECTDATA Open and plot a dataset which is selected by argin or explorer
%            
% Input arguments:  'dataset' - 'BaxterRand.mat',
%                               'BaxterRhythmic.mat',
%                               'URpickNplace.mat',
%                               'sarcos_inv.mat',
%                               default: Manually select dataset
%                   'fig'     - true (logical): (plot the dataset)
%                               false(logical): (do not plot the dataset)
%                               default: true
% Output arguments:   X: Input data [possition, velocity, acceleration]
%                     Y: Target data [Torque/Forces]
%                     measuredJoints: Number of measured joints
%                     actuatedJoints: Number of actuated joints
%
% syntax:   selectData():                 
%           selectData('dataset',string): 
%           selectData('dataset',string,'fig',false): 
%           selectData('fig',false):
%
% Author: W. van Dijk
% Date (version): 22-1-2019 (v1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Input parser
defaultFig = true;                  %Default: plot dataset
defaultDatasetName = 'default';
expectedDatasetNames = {'BaxterRand.mat',...
                        'BaxterRhythmic.mat',...
                        'URpickNplace.mat',...
                        'sarcos_inv.mat',...
                        };

p = inputParser;
addOptional(p,'dataset',defaultDatasetName,...
    @(x) any(validatestring(x,expectedDatasetNames)));
addOptional(p,'fig',defaultFig,@islogical);
parse(p,varargin{:});
filename = p.Results.dataset;       %name of dataset

%% Force user to select a dataset if not selected already
if length(varargin) == 0
    currentFolder = pwd;
    [filename,path,indx] = uigetfile([currentFolder,'\Data\InverseDynamics\BaxterRand.mat'],...
        'Select a Dataset');
    if isequal(filename,0)
        disp('User selected Cancel')
        error('No dataset selected...')
    else
        disp(['User selected ', filename])
    end
end

%% Load the data
currentFolder = pwd;
datasetPath = [currentFolder,'\Data\InverseDynamics\',filename];
switch filename
    case {'BaxterRand.mat','BaxterRhythmic.mat'}
        load(datasetPath);
        Ninput = 7;
        Ntarget = 7;
        X = [X_train; X_test];
        Y = [Y_train; Y_test];
        %measuredJoints = size(X,2)/3;
        %actuatedJoints = size(Y,2);
        t = 1:length(X);
    case {'sarcos_inv.mat','sarcos_inv_test.mat'}
        datasetPath = [currentFolder,'\Data\InverseDynamics\','sarcos_inv.mat'];
        load(datasetPath);
        Ninput = 7;
        Ntarget = 7;
        X_train = sarcos_inv(:,1:3*Ninput);
        Y_train = sarcos_inv(:,3*Ninput+1:end);
        
        datasetPath = [currentFolder,'\Data\InverseDynamics\','sarcos_inv_test.mat'];
        load(datasetPath);
        X_test = sarcos_inv_test(:,1:3*Ninput);
        Y_test = sarcos_inv_test(:,3*Ninput+1:end);
        X = [X_train; X_test];
        Y = [Y_train; Y_test];
        t = 1:length(X);
        
    case 'URpickNplace.mat'
        Ninput = 6;
        Ntarget = 6;
        load(datasetPath);
        X = urPicknPlace(:,1:3*Ninput);
        Y = urPicknPlace(:,3*Ninput+1:end);
        %X = urPicknPlaceHyper(:,1:3*measuredJoints);
        %Y = urPicknPlaceHyper(:,3*measuredJoints+1:end);
        t = 1:length(X);
        
end

%% Plot
if p.Results.fig == true
    figure;
    ha(1) = subplot(4,1,1);
    hold on
    plot(t,X(:,1:Ninput));
    xlim([0 t(end)]);
    title(['INPUT: Joint Position   (',filename,')'],'Interpreter','none');
    hold off
    
    ha(2) = subplot(4,1,2);
    hold on
    plot(t,X(:,Ninput+1:2*Ninput));
    xlim([0 t(end)]);
    title(['INPUT: Joint Velocity']);
    hold off
    
    ha(3) = subplot(4,1,3);
    hold on
    plot(t,X(:,2*Ninput+1:3*Ninput));
    xlim([0 t(end)]);
    title(['INPUT: Joint Acceleration']);
    hold off
    
    ha(4) = subplot(4,1,4);
    hold on
    plot(t,Y(:,1:Ntarget));
    xlim([0 t(end)]);
    title(['OUTPUT: Joint Torque']);
    xlabel('Samples');
    hold off
    
    set(gcf,'Color','White');
    linkaxes([ha(1:4)],'x');
end