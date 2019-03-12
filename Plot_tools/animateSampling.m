function [] = animateSampling(X,Y,ts,N,varargin)
%ANIMATESAMPLING Animate sampling methods on dataset
%            
% Input arguments:  'X' - input data
%                   'Y' - target data
%                   'N' - [Ninput,Ntarget] Number of inputs and targets
%                   'ts'- [s] Sample time (ts=0 means that no sample time
%                             is specified)
%                   'N_indc'     - (Optional) Number of inducing points
%                   'resamp'     - (Optional) Resample size
%                   'frameRate'  - (Optional) Plot every Nth frame
%                   'windowSize' - (Optional) number of samples of window
%                   'figNum'     - (Optional) Number of figure 
%                   'frameRate'  - (Optional) Plot a frame every frameRate
% Output arguments: '-'
%
% syntax:  	animateSampling(X,Y,ts,N)
%           animateSampling(X,Y,ts,N,'resamp',50)
%           animateSampling(X,Y,ts,N,'method',1,'windowSize',1000)
%           animateSampling(X,Y,ts,N,'windowSize',100,'figNum',2)
%
% Author: W. van Dijk
% Date: (v1)    22-2-2019: Create function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input parser
defaultMethod     = [1 1];      % Sampling method
defaultN_indc     = 10;     % Number of inducing points
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
addOptional(p,'method',defaultMethod,@(x) (size(x,1)==1 && size(x,2)==2));
addOptional(p,'N_indc',defaultN_indc,@(x) isinteger(x));
addOptional(p,'frameRate',defaultFrameRate);
addOptional(p,'windowSize',defaultWindowSize);
addOptional(p,'figNum',defaultFigNum);

parse(p,X,Y,ts,N,varargin{:});
method      = p.Results.method;
N_indc      = p.Results.N_indc;
resamp      = p.Results.resamp;
frameRate   = p.Results.frameRate;
windowSize  = p.Results.windowSize;
figNum      = p.Results.figNum;

%% Some stuff regarding required inputs
if ts == 0
    xlabelStr = 'samples';
    ts = 1;
    titleStr = ' samples';
else 
    xlabelStr = 'time [s]';
    titleStr = ' [s]';
end
Ninput = N(1);

%% Resample
X = X(1:resamp:end,:);
Y = Y(1:resamp:end,:);

%% Initialize animation
if figNum ~= 0
    h = figure(figNum);clf(h);
else
    h = figure;
end
set(gcf,'Color','White');

%Inititial window;
indi = zeros(1,windowSize);
%Sampling method
ii = initSampling(method(1),windowSize,N_indc);
for i = 1:frameRate:length(X)-1
    if i <= windowSize
        indi = [ones(1,windowSize-i),1:i];
    else 
        indi = [(i-windowSize):i];
    end
    %indi = indi+1;
    Xlimits = [indi(1)-5,indi(end)+5]*ts;
    t = indi*ts;
    
    % Select inducing points from window
    indi_indc = indi(ii);
    t_indc = indi_indc*ts;
        
    subplot(4,1,1);
    plot(t,X(indi,1:Ninput));
    hold on
    scatter(t_indc,X(indi_indc,1))';
    xlim(Xlimits);
    title(['INPUT: Joint Position,  Time: ',num2str(i*ts),titleStr]);
    hold off
    
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
       
    % update inducing points
    ii = updateSampling(method(2),ii,windowSize,frameRate);
    
end