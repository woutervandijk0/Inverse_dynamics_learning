function [] = animateData(X,Y,ts,N,varargin)
%ANIMATEDATA Animate the inverse dynamics data. 
%            
% Input arguments:  'X' - input data
%                   'Y' - target data
%                   'ts'- [s] Sample time (ts=0 means that no sample time
%                   is specified)
%                   'N' - [Ninput,Ntarget] Number of inputs and targets
%                   'resamp'  - resample size
% Output arguments: '-'
%
% syntax:  	animateData(X,Y,N)
%           animateData(X,Y,N,'resamp',50)
%
% Author: W. van Dijk
% Date (version): 22-1-2019 (v1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input parser
defaultResamp = 50;     %plot every Nth sample
p = inputParser;
addRequired(p,'X',@(x) length(x)>1);
addRequired(p,'Y',@(x) length(x)>1);
addRequired(p,'ts',@(x) (length(x)==1) && isnumeric(x) && isreal(x));
addRequired(p,'N',@(x) (size(x,1)==1 && size(x,2)==2));
addOptional(p,'resamp',defaultResamp);
parse(p,X,Y,ts,N,varargin{:});
resamp = p.Results.resamp;

%% Some stuff regarding required inputs
if ts == 0
    xlabelStr = 'samples';
    ts = 1;
else 
    xlabelStr = 'time [s]';
end
% Number of in-/outputs:
Ninput = N(1);
Ntarget = N(2);


%% Define default colororder;
colororder = [  0         0.4470    0.7410;
                0.8500    0.3250    0.0980;
                0.9290    0.6940    0.1250;
                0.4940    0.1840    0.5560;
                0.4660    0.6740    0.1880;
                0.3010    0.7450    0.9330;
                0.6350    0.0780    0.1840];

%% Initialize animation
% Input
figure(999);clf(999);
set(gcf,'Color','White');
xlimits = [0 length(X)];
for i = 1:Ninput
    ha(1) = subplot(4,1,1);
    hold on
    pos(i)=animatedline('Color',colororder(i,:));
    xlim(xlimits);
    title(['INPUT: Joint Position']);
    
    ha(2) = subplot(4,1,2);
    vel(i)=animatedline('Color',colororder(i,:));
    xlim(xlimits);
    title(['INPUT: Joint Velocity']);
    
    ha(3) = subplot(4,1,3);
    acc(i)=animatedline('Color',colororder(i,:));
    xlim(xlimits);
    title(['INPUT: Joint Acceleration']);
end

%Target
for i = 1:Ntarget
    ha(4) = subplot(4,1,4);
    hold on
    target(i)=animatedline('Color',colororder(i,:));
    title(['OUTPUT: Joint Torque']);
    xlim(xlimits);
    xlabel(xlabelStr);
end
%% Run animation
t = 1:length(X);
for k=1:resamp:length(X)
    for i = 1:Ninput
        addpoints(pos(i),t(k),X(k,i));
        addpoints(vel(i),t(k),X(k,Ninput+i));
        addpoints(acc(i),t(k),X(k,2*Ninput+i));
    end
    for i = 1:Ntarget
        addpoints(target(i),t(k),Y(k,i));
    end
    drawnow
    %pause(0.01);
end
linkaxes([ha(1:4)],'x');
