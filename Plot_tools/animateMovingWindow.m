function [] = animateMovingWindow(X,Y,ts,N,varargin)
%ANIMATEMOVINGWINDOW Animate a moving window of the dataset
%            
% Input arguments:  'X' - input data
%                   'Y' - target data
%                   'N' - [Ninput,Ntarget] Number of inputs and targets
%                   'ts'- [s] Sample time (ts=0 means that no sample time
%                   is specified)
%                   'resamp'     - (Optional) Resample size
%                   'frameRate'  - (Optional) Plot every Nth frame
%                   'windowSize' - (Optional) number of samples of window
%                   'figNum'     - (Optional) Number of figure 
%                   'frameRate'  - (Optional) Plot a frame every frameRate
% Output arguments: '-'
%
% syntax:  	animateMovingWindow(X,Y,ts,N)
%           animateMovingWindow(X,Y,ts,N,'resamp',50)
%           animateMovingWindow(X,Y,ts,N,'resamp',50,'windowSize',1000)
%           animateMovingWindow(X,Y,ts,N,'windowSize',100,'figNum',2)
%
% Author: W. van Dijk
% Date: (v1)    22-2-2019: Create function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input parser
defaultResamp     = 50;     % Resample rate
defaultFrameRate  = 1;      % Plote every Nth frame
defaultWindowSize = 500;    % Size of moving window
defaultFigNum     = 0;      % Figure number

p = inputParser;
addRequired(p,'X',@(x) length(x)>1);
addRequired(p,'Y',@(x) length(x)>1);
addRequired(p,'ts',@(x) (length(x)==1) && isnumeric(x) && isreal(x));
addRequired(p,'N',@(x) (size(x,1)==1 && size(x,2)==2));
addOptional(p,'resamp',defaultResamp);
addOptional(p,'frameRate',defaultFrameRate);
addOptional(p,'windowSize',defaultWindowSize);
addOptional(p,'figNum',defaultFigNum);

parse(p,X,Y,ts,N,varargin{:});
resamp      = p.Results.resamp;
frameRate   = p.Results.frameRate;
windowSize  = p.Results.windowSize;
figNum      = p.Results.figNum;

%% Some stuff regarding required inputs
if ts == 0
    xlabelStr = 'samples';
    ts = 1;
else 
    xlabelStr = 'time [s]';
end
Ninput = N(1);

%% Define default colororder;
colororder = [  0         0.4470    0.7410;
                0.8500    0.3250    0.0980;
                0.9290    0.6940    0.1250;
                0.4940    0.1840    0.5560;
                0.4660    0.6740    0.1880;
                0.3010    0.7450    0.9330;
                0.6350    0.0780    0.1840];

%% Resample
X = X(1:resamp:end,:);
Y = Y(1:resamp:end,:);

%% Initialize animation
if figNum ~= 0
    figure(123);clf(123);
else
    figure;
end
set(gcf,'Color','White');

indi = zeros(1,windowSize);
for i = 1:frameRate:length(X)-1
    if i <= windowSize
        indi = [ones(1,windowSize-i),1:i];
    else 
        indi = [(i-windowSize):i];
    end
    %indi = indi+1;
    Xlimits = [indi(1)-5,indi(end)+5]*ts;
    t = indi*ts;
    
    subplot(4,1,1);
    plot(t,X(indi,1:Ninput));
    xlim(Xlimits);
    title(['INPUT: Joint Position']);
    
    subplot(4,1,2);
    plot(t,X(indi,Ninput+1:2*Ninput));
    xlim(Xlimits);
    title(['INPUT: Joint Velocity']);
    
    subplot(4,1,3);
    plot(t,X(indi,2*Ninput+1:3*Ninput));
    xlim(Xlimits);
    title(['INPUT: Joint Acceleration']);
    
    %Target
    subplot(4,1,4);
    plot(t,Y(indi,:));
    xlim(Xlimits)
    xlabel(xlabelStr)
    title(['TARGET: Torque/Current'])
    hAx = gca;             % handle to current axes
    hAx.XAxis.TickLabelFormat='%.2f'; % use integer format, no decimal points
    
    drawnow
end