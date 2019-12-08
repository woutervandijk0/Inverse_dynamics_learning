function [u,freq,amplitude,phase_vector,crestFactor] = multisine(ts,band,N,bin,varargin)
%MULTISINE Create a multisine for indentification
%
% Input arguments:      ts    - [s]  Sample time
%                       band  - [Hz] Frequency band, [f_min,f_max]
%                       N     - []   Number of frequencies
%                       bin   - []   Common divider of frequencies
%                      'Fig'  - [bool] Plot results [true/false]
%                      'FigNum'  - [] Figure number
%                      'Periods' - [] Number of periods
%                      'Spacing' -    Spacing of frequencies; ['lin'/'log']
%                      'Method'  -    Method of initializing phases 
%                                     ['Schroeder'/'Ojarand'/'Random']
%                      'Optimize'-    Optimize phase with fminsearch
%                                     [true/false]
%                      'MaxIter' - [] Max. iterations for fminsearch

% Output arguments:     u      - []   Multisine signal u(t)
%                       freq   - [Hz] Vector containing frequencies in
%                                     multisine
%                       amplitude - [] Ampltitude at each frequency
%
% syntax:   multisine():
%
% Author: W. van Dijk
% Date: (v1)    15-8-2019: Create function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input parser
%Defaults
defaultFig       = true;
defaultFigNum    = 0;
defaultPeriods   = 5;
defaultAmplitude = 1;
defaultSpacing   = 'lin';
expectedSpacing  = {'lin',...
                    'log'};
defaultMethod    = 'Schroeder';
expectedMethod   = {'Schroeder',...
                    'Ojarand',...
                    'Random'};
defaultOpti      = false;
defaultMaxIter   = 20;
defaultPlant     = 0;

% Create input parse
p = inputParser;
addOptional(p,'Periods',defaultPeriods,@(x) x>0 && mod(x,1)==0);
addOptional(p,'Fig',defaultFig,@islogical);
addOptional(p,'Amplitude',defaultAmplitude,@isreal);
addOptional(p,'FigNum',defaultFigNum,@(x) x>=0 );
addOptional(p,'Spacing',defaultSpacing,...
    @(x) any(validatestring(x,expectedSpacing)));
addOptional(p,'Method',defaultMethod,...
    @(x) any(validatestring(x,expectedMethod)));
addOptional(p,'Optimize',defaultOpti,@islogical);
addOptional(p,'MaxIter',defaultMaxIter,@(x) x>0 && mod(x,1)==0);
addOptional(p,'Plant',defaultPlant)

% Parse variables
parse(p,varargin{:});
periods   = p.Results.Periods;    % Number of periods
figNum    = p.Results.FigNum;     % Figure number
showFig   = p.Results.Fig;        % Plot figure (yes/no)
spacing   = p.Results.Spacing;    % Frequency spacing
amplitude = p.Results.Amplitude;  % Amplitude of each frequency bin
method    = p.Results.Method;     % Phase initialisation method
optimize  = p.Results.Optimize;   % Numerical phase optimisation (yes/no)
maxIter   = p.Results.MaxIter;    % Max. iterations for fminsearch
plant     = p.Results.Plant;
%% Calculate frequencies, amplitude and phase
fs      = 1/ts;     %[Hz] Sample  frequency
fs_nyq  = fs/2;     %[Hz] Nyquist frequency
period  = 1/bin;    %[s] Period of signal
t = 0:ts:(periods*period-ts);   %[s] Time vector
L = length(t);                  %    Length of signal

% Check if band is within limits
if fs_nyq < band(2)
    band(2) = fs_nyq;
    warning('Upper frequency is larger than the Nyquist frequency. band(2) > fs_nyq');
    disp('Upper frequency adjusted to the Nyquist frequency...');
end
if band(1) < 0.1
    band(1) = 0.1;
end
if band(1) < bin
    warning('Lower frequency is smaller than the frequency bin size. band(1) < bin');
    disp('Lower frequency adjusted to the frequency bin size...');
    band(1) = bin;
end

% Choose frequency spacing
switch spacing
    case 'lin'
        freq  = bin.*round(linspace(band(1),band(2),N)./bin);
    case 'log'
        freq  = bin.*round(logspace(log10(band(1)),log10(band(2)),N)./bin);
end
freq = unique(freq);
N    = length(freq);

amplitude = (ones(1,N).*amplitude)';
%{
    [mag] = bode(plant,freq*pi);
    mag = mag2db(mag(:));
    mag = (mag - sign(min(mag))*abs(min(mag)));
    mag = mag/std(mag)+1;
    scaling = 1./mag;
    amplitude = amplitude.*scaling;
%}
if freq(1) == 0
    freq(1) = bin;
end

%% Crest optimalisation using Schroeder or Ojarand (2017)
% Source: Recent Advances in Crest Factor Minimization of Multisine. (2017) J. Ojarand & M. Min
crest_min = inf;        % Initial minimum crest value (very high)
for m = 1:180
    phaseInit = m;
    switch method
        case 'Schroeder'
            [phase] = schroeder(phaseInit,N,freq,bin);
        case 'Ojarand'
            [phase] = ojarand(phaseInit,N,freq,bin);
        case 'Random' 
            break                   % No need for loop with random phases
    end
    [crestFactor] = crestRatio(phase,t,ts,period,N,amplitude,freq);
    %Store the best initial phase
    if crestFactor < crest_min
        crest_min = crestFactor;
        bestPhase = phaseInit;
    end
end
%% Switch between methods
switch method
    case 'Schroeder'
        fprintf('\nphi_0 = %i \n',bestPhase)
        [phase] = schroeder(bestPhase,N,freq,bin);
    case 'Ojarand'
        fprintf('\nB = %i \n',bestPhase)
        [phase] = ojarand(bestPhase,N,freq,bin);
    otherwise
        phase = rand(N,1).*180-90;
end

%% Numerical optimization of phase
if optimize == true
    option = optimset;
    option.MaxIter = maxIter;
    %option.DiffMinChange = 0.5;
    %phase = fminsearch(@(phase)crestRatio(phase,t,ts,period,N,amplitude,freq),phase,option);
    phase = fmincon(@(phase)crestRatio(phase,t,ts,period,N,amplitude,freq),phase,[],[],[],[],[],[],[],option);
end

%% Final multisine & Crest Ratio
phase_vector = phase;
phase = ones(N,length(t)).*phase;
b = amplitude.*sin(2*pi*freq'*t + phase);       % Seperate sinusoids
u = sum(b,1);                                   % Multisine signal
crestFactor = max(abs(u))/rms(u);               % Calculate crest factor

%% Fourier transform
Y   = fft(u);                   % Fast fourier transform
f   = fs*(0:(L/2))/L;           % [Hz] Frequency vector
P2  = abs(Y/L);                 % Normalize
% Single right side
P1  = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

%% Show results
if showFig == true
    if figNum ~= 0
        figID = figure(figNum);clf(figID);
    else
        figID = figure;
    end 
    set(gcf,'Color','White');
    
    fontSize   = 8;
    labelSize  = 11;
    legendSize = 8;
    
    ha(1,1) = subplot(2,1,1)
    set(gca,'FontSize',fontSize);

    plot(t,u)
    %title(['Multisine, Crest Ratio: ',num2str(crestFactor)])
    xlabel('t (s)','Interpreter','Latex','FontSize',labelSize);
    ylabel('$u(\mathrm{t})$','Interpreter','Latex','FontSize',labelSize);
    
    ha(2,1) = subplot(2,1,2)
    set(gca,'FontSize',fontSize);
    plot(f,P1);
    ylim([0 1.1*max(P1)]);
    %title(['Spectrum of u(t), f_{nyq}=',num2str(fs_nyq)])
    xlabel('f (Hz)','Interpreter','Latex','FontSize',labelSize);
    ylabel('$|U(\mathrm{f})|$','Interpreter','Latex','FontSize',labelSize);
    
    set(gcf,'PaperSize',[8.4 8.4*3/4+0.1],'PaperPosition',[0 0.2 8.4 8.4*3/4+0.2]);
end
end

%% Functions 
function [crest] = crestRatio(phase,t,ts,period,N,amplitude,freq)
Phase = ones(N,period/ts).*phase;
b = amplitude.*sin(2*pi*freq'*t(1:period/ts) + phase);   % Seperate sinusoids
u = sum(b,1);                               % Multisine signal
crest = max(abs(u))/rms(u);                 % Calculate crest factor
end

% Source: Recent Advances in Crest Factor Minimization of Multisine. (2017) J. Ojarand & M. Min
% Eq.(3)
function [phase] = schroeder(phaseInit,N,freq,bin)
i = freq./bin;
phase = zeros(N,1);
phase(1) = phaseInit;
for j = 2:N
    phase(j) = phase(1) - pi.*i(j).^2./N;      % Eq.(3)
end
end

% Source: Recent Advances in Crest Factor Minimization of Multisine. (2017) J. Ojarand & M. Min
% Eq.(4)
function [phase] = ojarand(B,N,freq,bin)
i = freq./bin;

phase = zeros(N,1);
for j = 1:N
    phase(j) = B.*i(j).^2;      % Eq.(4)
end
end