clc, clear all

ts = 1/1000;
t0 = 0;
T  = 20;

alpha_T = 0.0001;
alpha_0 = 1;

beta_0 = nthroot(alpha_T/alpha_0,(T-t0)/ts)

%% Multisine
%{
period     = 100;
numPeriod  = 5;
band       = [0.2,0.5]
range      = [-1,1]

[u,freq] = idinput([period,1,numPeriod],'sine',band,range)
plot(u)

Ts = 1/1000;   % s
freq = freq/Ts;
freq(1)

%}
%% multisine 2
%{
fCommon = 1;        %
ts   = 1/1000;      %[s]  Sample time
fs = 1/ts;
numPeriods  = 5;
fMin = 1;           %[Hz]
fMax = 200;         %[Hz]
fNum = 21;           %Number of frequencies

period  = 1/fCommon;    %
t = 0:ts:(numPeriods*period-ts);   %
L = length(t);

%freq  = round(logspace(log10(fMin),log10(fMax),fNum));
freq  = round(linspace(fMin,fMax,fNum));
amp   = 1;

%Schroeder phase calculation (for low crest factor)
phase = zeros(fNum,1);

crest_min = inf;
for m = 1:360
    phase = zeros(fNum,1);
    phase(1) = m;
    for i = 2:fNum
        phase(i) = phase(1) - pi.*i.^2./fNum;
    end
    phase = ones(fNum,length(t)).*phase;
    
    b = amp.*sin(2*pi*freq'*t + phase);
    u = sum(b,1);
    
    crest = max(abs(u))/rms(u);
    if crest < crest_min
        disp(phase(1))
        crest_min = crest;
        phase1 = phase(1);
    end
end

phase(1) = phase1;
for i = 2:fNum
    phase(i) = phase(1)- pi.*i.^2./fNum;
end
phase = ones(fNum,length(t)).*phase;

b = amp.*sin(2*pi*freq'*t + phase);
u = sum(b,1);

crest = max(abs(u))/rms(u);

figure(1),clf(1);
subplot(2,1,1)
plot(t,u)
title(['Multisine u(t), Crest Ratio: ',num2str(crest)])
xlabel('t (s)')

%% Fourier transform
Y = fft(u);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = fs*(0:(L/2))/L;

subplot(2,1,2)
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of u(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')
%}

ts   = 1/1000;
band = [1,10];
N    = 20;
bin  = 0.5;

[u,freq,amplitude] = multisine(ts,band,N,bin,'Method','Ojarand','Optimize',false,'MaxIter',1e4);
