function [X,Y,ts,N] = selectData(varargin)
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
%                   'figNum'     - (Optional) Number of figure 
%
% Output arguments:   X:  Input data [possition, velocity, acceleration]
%                     Y:  Target data [Torque/Forces]
%                     ts: Sample time of dataset
%                     N:  [N_inputs N_targets]; Dimension of in- and outputs
%
% syntax:   selectData():                 
%           selectData('dataset',string): 
%           selectData('dataset',string,'fig',false): 
%           selectData('fig',false):
%
% Author: W. van Dijk
% Date: (v1)    22-1-2019: Create function
%       (v1.1)  22-2-2019: Add figNum, bug fixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input parser
defaultFig = true;                  %Default: plot dataset
defaultFigNum = 0;
defaultDatasetName = 'Default';
expectedDatasetNames = {'Default',...
                        'BaxterRand.mat',...
                        'BaxterRhythmic.mat',...
                        'URpickNplace.mat',...
                        'sarcos_inv.mat',...
                        'DoublePendulum.mat',...
                        'DoublePendulumWithNoise.mat',...
                        'TFlex1D.mat',...
                        'TFlex1D5G.mat',...
                        'TFlex1D-2.mat',...
                        'TFlexADRC_RN20.mat',...
                        };

p = inputParser;
addOptional(p,'dataset',defaultDatasetName,...
    @(x) any(validatestring(x,expectedDatasetNames)));
addOptional(p,'fig',defaultFig,@islogical);
addOptional(p,'figNum',defaultFigNum,@(x) x>=0 );

parse(p,varargin{:});
filename = p.Results.dataset;       %name of dataset
figNum = p.Results.figNum;       %name of dataset
%% Force user to select a dataset if not selected already
if strcmp(filename,defaultDatasetName)== 1
    currentFolder = pwd;
    [filename,path,indx] = uigetfile([currentFolder,'\Data\InverseDynamics\BaxterRand.mat'],...
        'Select a Dataset');
    if isequal(filename,0)
        %disp('User selected Cancel')
        error('File explorer cancelled...');
    else
        disp(['User selected ', filename]);
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
        ts = 1/1000;
        xlabelStr = 'time (s)';
        
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
        ts = 1/1000;
        xlabelStr = 'time (s)';
        
    case 'URpickNplace.mat'
        Ninput = 6;
        Ntarget = 6;
        load(datasetPath);
        X = urPicknPlace(:,1:3*Ninput);
        Y = urPicknPlace(:,3*Ninput+1:end);
        %X = urPicknPlaceHyper(:,1:3*measuredJoints);
        %Y = urPicknPlaceHyper(:,3*measuredJoints+1:end);
        t = 1:length(X);
        ts = 1/1000;
        xlabelStr = 'time (s)';
        
    case {'DoublePendulum.mat','DoublePendulumWithNoise.mat'}
        Ninput  = 2;
        Ntarget = 2;
        load(datasetPath);
        ts = 1/1000;
        t = [1:length(X)]*ts;
        xlabelStr = 'time (s)';
        
    case {'TFlex1D.mat','TFlex1D-2.mat','TFlex1D5G.mat','TFlexADRC_RN20.mat'}
        Ninput = 1;
        Ntarget = 1;
        load(datasetPath);
        ts = 1/1000;
        t = [1:length(X)]*ts;
        xlabelStr = 'time (s)';
end
N = [Ninput Ntarget];

%% Plot
if p.Results.fig == true
    if figNum ~= 0
       figure(figNum),clf(figNum);
    else
       figure; 
    end
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
    xlabel(xlabelStr);
    hold off
    
    set(gcf,'Color','White');
    linkaxes([ha(1:4)],'x');
end
