% function [FRFmag, FRFphase, FRFwout] = resp(input , output , window , Fs)
function [FRFperiodic] = resp(u , y , window , Fs)

% This function computes the FRF's of signals that are periodic. This is in
% contrast to arbitrary excitations, which requires spectral analysis

% u      = Input time data
% y      = Output time data
% window = Window (e.g. Hann(N) or ones(N,1) with N the number of samples in one period)
% Fs     = Sample rate


%Ensure that time vectors have dimensions Nmeas x Nu and Nmeas x Ny 
if size(u,1) < size(u,2)
    u = u.';
end
if size(y,1) < size(y,2)
    y = y.';
end

N = length(window);

% Define number of inputs and outputs
Nu = size(u, 2);
Ny = size(y, 2);


%% Divide in subrecords and apply windowing

%Ensure that window is a given by a row vector
if size(window,1) == 1
    window = window.';
end

% Define window for each input and output signal
winu = repmat(window, [1, Nu]);
winy = repmat(window, [1, Ny]);

% Divide data into subrecords and apply windowing
P = floor((size(u, 1))/N);   %Number of subrecords
if P == 0
    disp('ERROR: Insufficent datapoints to fill one subrecord, process aborted.')
    outputdata = [];
    return
end
um = zeros(N,Nu,P);
ym = zeros(N,Ny,P);
for kk = 1:P
    first = 1 + (kk-1)*N;
    last = N + (kk-1)*N;
    um(:, :, kk) = u(first : last, :) .* winu;
    ym(:, :, kk) = y(first : last, :) .* winy;
end

%% Convert subrecords to frequency domain

%Calculate FFT
DFTscaling = sqrt(sum(abs(winu(:,1)).^2));  %See Pintelon/Schoukens, (7-32)
Um = fft(um,[],1) ./ DFTscaling;
Ym = fft(ym,[],1) ./ DFTscaling;

%Remove DC-term and all information beyond the Nyquist frequency
Um = Um(2:size(Um,1)/2,:,:);
Ym = Ym(2:size(Ym,1)/2,:,:);

%Frequency axis for FFT
f = (10^(-1):floor(N/2)-1).*Fs/N;
Nf = length(f);

%% Calculate averaged spectral matries

%Initialize matrices
Umat_av = zeros(1, Nu , Nf);
Ymat_av = zeros(1, Ny , Nf);

%Loop over the frequencies
for k = 1 : Nf
    %Construct Umat, Ymat for the specific frequency
    Umat_f = squeeze(Um(k,:,:));
    Ymat_f = squeeze(Ym(k,:,:));
    
    %Ensure that Umat_f, Ymat_f have dimension Nu x P
    if size(Umat_f,2)==Nu
        Umat_f = Umat_f.';
    end
    if size(Ymat_f,2)==Ny
        Ymat_f = Ymat_f.';
    end
    
    %Averaged spectra (Scale with Nyquist frequency to obtain power
    %spectral density in [unit^2/Hz] rather than power spectrum in [unit^2]
    Umat_av(:,:,k) =  (1/P) .* sum(Umat_f,2);
    Ymat_av(:,:,k) =  (1/P) .* sum(Ymat_f,2);
%     mag_est = Ymat_av(:,:,k)/Umat_av(:,:,k);
%     Syu(:,:,k) = (1/(0.5*fs)) .* (1/P) .* (Ymat_f * Umat_f');
%     Syy(:,:,k) = (1/(0.5*fs)) .* (1/P) .* (Ymat_f * Ymat_f');
    
end


FRFperiodic = frd(Ymat_av./Umat_av, f, 1/Fs, 'frequencyunit', 'hz');





% Nwin = stop_time/T;
% N = T*Fs; % Number of samples in one window
% FFT_scaling_factor = sqrt(N); % DFT scaling for MATLAB
% 
% fft_u = fft(u(Fs*stop_time-N*(Nwin-win+1)+1 : Fs*stop_time-N*(Nwin-win)+1)); % VERY IMPORTANT: FIRST SPECIFY WINDOW, I.E. WHICH SAMPLES ARE BEING FFT'T, OTHERWISE THE SCALING DOES NOT WORK
% fft_y = fft(y(Fs*stop_time-N*(Nwin-win+1)+1 : Fs*stop_time-N*(Nwin-win)+1));
% 
% fft_u = fft_u./FFT_scaling_factor;
% fft_y = fft_y./FFT_scaling_factor;
%             
% FRFmag = abs(fft_y)./abs(fft_u);
% FRFphase = angle(fft_y)./angle(fft_u);
% FRFwout = linspace(0,Fs,N+1)*2*pi;
% 










% Nwin = stop_time/T;
% N = T*Fs; % Number of samples in one window
% FFT_scaling_factor = sqrt(N); % DFT scaling for MATLAB
% 
% fft_u = fft(input);
% fft_y = fft(output);
% 
% fft_u = fft_u(Fs*stop_time-N*(Nwin-win)+1 : Fs*stop_time-N*(Nwin-win-1)+1)./FFT_scaling_factor;
% fft_y = fft_y(Fs*stop_time-N*(Nwin-win)+1 : Fs*stop_time-N*(Nwin-win-1)+1)./FFT_scaling_factor;
% 
% % fft_mag_u = abs(fft_u);
% % fft_mag_y = abs(fft_y);
% 
% fft_angle_u = angle(fft_u);
% fft_angle_y = angle(fft_y);
%              
% FRFmag = abs(fft_y)./abs(fft_u);
% FRFphase = fft_angle_y./fft_angle_u;
% FRFwout = linspace(0,Fs,N+1)*2*pi;








% Nwin = stop_time/T;
% N = T*Fs; % Number of samples in one window
% FFT_scaling_factor = sqrt(N); % DFT scaling for MATLAB
% 
% % fft_u = fft(input)./FFT_scaling_factor;
% % fft_y = fft(output)./FFT_scaling_factor;
% % 
% % fft_u = fft_u(Fs*stop_time-N*(Nwin-win)+1 : Fs*stop_time-N*(Nwin-win-1)+1);
% % fft_y = fft_y(Fs*stop_time-N*(Nwin-win)+1 : Fs*stop_time-N*(Nwin-win-1)+1);
% % 
% % fft_mag_u = abs(fft_u);
% % fft_mag_y = abs(fft_y);
% 
% fft_mag_u = abs(fft(input(Fs*stop_time-N*(Nwin-win)+1 : Fs*stop_time-N*(Nwin-win-1)+1)));
% fft_mag_y = abs(fft(output(Fs*stop_time-N*(Nwin-win)+1 : Fs*stop_time-N*(Nwin-win-1)+1)));
% 
% % fft_angle_u = angle(fft_u);
% % fft_angle_y = angle(fft_y);
% 
% fft_angle_u = angle(fft(input(Fs*stop_time-N*(Nwin-win)+1 : Fs*stop_time-N*(Nwin-win-1)+1)));
% fft_angle_y = angle(fft(output(Fs*stop_time-N*(Nwin-win)+1 : Fs*stop_time-N*(Nwin-win-1)+1)));
%              
% FRFmag = fft_mag_y./fft_mag_u;
% FRFphase = fft_angle_y./fft_angle_u;
% FRFwout = linspace(0,Fs,N+1)*2*pi;
% 












end