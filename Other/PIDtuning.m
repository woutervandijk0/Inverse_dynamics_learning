clc, clear all, close all

%% Settings
ts   = 1/1000;          %[s]  Sample time
fs   = 1/ts;            %[Hz] Sample rate
freq = 0.1:0.1:100;     %[Hz] Frequency vector


%% Estimated plant
s = tf('s');
m_eq = 0.15;            % Equivalent mass
w_n  = 1.65*2*pi;       % [rad/s] Natural Frequency     
k_eq = m_eq*(w_n).^2;   % Equivalent Stiffness
d_eq = 0.5;             % Equivalent Damping

P = 1/(m_eq*s^2 + d_eq*s + k_eq)*exp(-0.004*s);

%% PID controller
m_eq  = 0.15;     % Equivalent mass
[C15,C15_d] = tunePID(7*2*pi,m_eq,ts);
[C35,C35_d] = tunePID(20*2*pi,m_eq,ts);

%% Calc Bode plot
[magP,phaseP,woutP]       = bode(P,freq*2*pi);
[magC15P,phaseC15P,woutC15P]    = bode(C15*P,freq*2*pi);
[magC35P,phaseC35P,woutC35P]    = bode(C35*P,freq*2*pi);

magP   = magP(:);
magC15P = magC15P(:);
magC35P = magC35P(:);
phaseP   = phaseP(:);
phaseC15P = phaseC15P(:);
phaseC35P = phaseC35P(:);

[Gm15,Pm15,Wcg15,Wcp15] = margin(C15*P);
[Gm35,Pm35,Wcg35,Wcp35] = margin(C35*P);

%% Plot results
% Figure settings
fontSize   = 8;
labelSize  = 11;
legendSize = 8;

figure(11)
clear ha
figureFRF = figure(11); clf(figureFRF);
ha(1,1) = subplot(2,1,1);
set(gca,'FontSize',fontSize);
semilogx(woutP/(2*pi),mag2db(magP),'-k','Linewidth',1)
hold on
semilogx(woutC15P/(2*pi),mag2db(magC15P),'--','Linewidth',1)
semilogx(woutC35P/(2*pi),mag2db(magC35P),'-.','Linewidth',1)
ylabel('magnitude (dB)','Interpreter','Latex','FontSize',labelSize)
legend('$TF(s)$','$C_{7\mathrm{Hz}}TF(s)$','$C_{20\mathrm{Hz}}TF(s)$','Interpreter','Latex','FontSize',legendSize)
xlim([0.1 100])
ylim([-100 130])
grid on
hold off

ha(2,1) = subplot(2,1,2);
set(gca,'FontSize',fontSize);
semilogx(woutP/(2*pi),phaseP,'-k','Linewidth',1)
hold on
semilogx(woutC15P/(2*pi),phaseC15P,'--','Linewidth',1)
semilogx(woutC35P/(2*pi),phaseC35P,'-.','Linewidth',1)
semilogx([Wcp15,Wcp15]./(2*pi),[-180 -180+Pm15],'-k')
semilogx([Wcp35,Wcp35]./(2*pi),[-180 -180+Pm35],'-k')
semilogx(woutP/(2*pi),ones(size(woutP))*-180,':k')
ylabel('phase (deg)','Interpreter','Latex','FontSize',labelSize)
xlabel('f (Hz)','Interpreter','Latex','FontSize',labelSize)
xlim([0.1 100])
grid on
hold off

[figureFRF ,ha] = subplots(figureFRF,ha,'gabSize',[0.09, 0.04]);
ha(1,1).Position = [0.1300    0.5375-0.0875/2    0.8225    0.3875+0.0875/2];
ha(2,1).Position = [0.1300    0.1100    0.8225    0.3875-0.0875/2];
set(gcf,'PaperSize',[8.4+0.6 8.4*3/4+0.3],'PaperPosition',[0+0.4 0.3 8.4+0.4 8.4*3/4+0.3])

%% Save figure
saveFig = 1;
if saveFig == 1
    saveas(figureFRF,fullfile(pwd,'Images','PhaseMargin.pdf'))
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end
