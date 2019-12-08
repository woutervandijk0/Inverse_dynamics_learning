function [figure,handles] = subplots(figure,handles,varargin)

%% Input parser
defaultGabSize  = [0.09, 0.02];      % [horizontal, vertical]
defaultXMargin   = [0.1300, 0.0950/2];% [Left      ,    right]
defaultYMargin   = [0.1100, 0.0750];  % [lower     ,    upper]
defaultXTickLabel = 0;
expectedLinkAxes  = {'x','xy','y','off'};
defaultLinkAxes   = 'x';

p = inputParser;
checkMargins = @(x) (length(x)== 2 && max(x)<0.5);
addOptional(p,'gabSize',defaultGabSize,@(x)checkMargins(x));
addOptional(p,'xMargin',defaultXMargin,@(x)checkMargins(x));
addOptional(p,'yMargin',defaultYMargin,@(x)checkMargins(x));
addOptional(p,'xTickLabel',defaultXTickLabel,@(x) (length(x)==1) && (x==1 || x==0));
addOptional(p,'linkAxes',defaultLinkAxes,@(x) any(validatestring(x,expectedLinkAxes)));
parse(p,varargin{:});

gabSize = p.Results.gabSize;       
xMargin  = p.Results.xMargin;
yMargin  = p.Results.yMargin;        
xTickLabel  = p.Results.xTickLabel;
linkAxes = p.Results.linkAxes;

%%
m       = size(handles,1);
n       = size(handles,2);
mGab    = m-1;
nGab    = n-1;

%% Adjust axes positions
xWork   = (1-sum(xMargin) - nGab*gabSize(1))/n;
yWork   = (1-sum(yMargin) - mGab*gabSize(2))/m;
for i = 1:m
    for j = 1:n
        pos = [xMargin(1)+(j-1)*(xWork + gabSize(1)),...
            yMargin(1)+(m-i)*(yWork+gabSize(2)),...
            xWork, yWork ];
        handles(i,j).Position = pos;
        if (i ~= m) && (xTickLabel==0)
            handles(i,j).XTickLabel = [];
        end
    end
end
linkaxes(handles,linkAxes)
set(figure,'Color','White');
drawnow;
