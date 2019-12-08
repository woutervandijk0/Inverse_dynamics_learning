clc, clear all
saveFig = 0;

ts   = 1/1000;
band = [0.1,150];
N    = 100;
bin  = 0.1;

s = tf('s');
m_eq = 0.15;
w_n = 1.5*2*pi;
k_eq = m_eq*(w_n).^2;
d_eq = 0.74;
P = 1/(m_eq*s^2 + d_eq*s + k_eq);

[u,freq,amplitude,phase,crest] = multisine(ts,band,N,bin,'Periods',3,'Method','Ojarand','Optimize',true,'Spacing','log','Amplitude',1);
xlim([0 151]);
figID = gcf;


u_in = [zeros(1,20/ts),u,zeros(1,5/ts)];
t = [0:(size(u_in,2)-1)]*ts;
t_end = t(end);

multisine.time = t';
multisine.signals.values = u_in';
multisine.dimensions = [1,1];

%% Save figure
if saveFig == 1
    saveas(figID,fullfile(pwd,'Images','Multisine.pdf'));
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''});
end

crest