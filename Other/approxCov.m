
%
l  = 1;
sf = sqrt(1);
sn = sqrt(0.1);

x = linspace(-5,5,5000)';


D = 100;
n = 1;
RAND  = randn(D,n); % 
RAND_0 = RAND;
SIGMA = RAND.*(1./l);


phi   = sf^2./sqrt(D) .*[cos(SIGMA*x')',...
                       sin(SIGMA*x')']';
                   
phi5   = sf^2./sqrt(D) .*[cos(SIGMA*0')',...
                       sin(SIGMA*0')']';
                   
A5 = phi'*phi5;
A = phi'*phi;

K5 = SEcov(x,0,[l,sf]);
K = SEcov(x,x,[l,sf]);

figure(1),clf(1)
hold on
plot(x,K5)
plot(x,A5,'--')
hold off
%% SE cov
% Some figure settings
fontSize   = 12;
labelSize  = 15;
titleSize  = 15;
legendSize = 12;

figure(3),clf(3)
imagesc(A)
title('$\phi(\mathbf{x})^T \phi(\mathbf{x})$, $D=100$','Interpreter','Latex','FontSize',titleSize)
xlabel('$x$','Interpreter','Latex','FontSize',labelSize)
ylabel('$x$','Interpreter','Latex','FontSize',labelSize)
set(gca,'YTickLabel','','XTickLabel','')
set(gcf,'PaperSize',[8.8 7.8],'PaperPosition',[0 0 8.8 7.8])



figure(4),clf(4)
imagesc(K)
title('$K(\mathbf{x},\mathbf{x})$','Interpreter','Latex','FontSize',titleSize)
xlabel('$x$','Interpreter','Latex','FontSize',labelSize)
ylabel('$x$','Interpreter','Latex','FontSize',labelSize)
set(gca,'YTickLabel','','XTickLabel','')
set(gcf,'PaperSize',[8.8 7.8],'PaperPosition',[0 0 8.8 7.8])

%%
saveas(figure(3),fullfile(pwd,'Images','approxCov.pdf'))
saveas(figure(4),fullfile(pwd,'Images','trueCov.pdf'))
pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})



% Run monte carlo simulation
%{
rmsError = zeros(10,5);
maxError = zeros(10,5);
rmsFB    = zeros(10,5);

% Run simulations

DD = [4:2:30]
tic
for kkk = 1:length(DD)
    for jjj = 1:5
        t_learn     = 1;          %[s] Start updating posterior
        t_predict   = 50-9;       %[s] Make predictions
        D = DD(kkk);
        Train_SSGP;
        close all
        TFlex_ISSGP_init;
        
        rmsError(kkk,jjj) = RMS_ERROR;
        maxError(kkk,jjj) = MAX_ERROR;
        rmsFB(kkk,jjj)    = RMS_FB;
    end
end
toc;
%}

%Monte carlo results
%{
load('monteCarlo_5_opti.mat')
rmsError_opti = rmsError;
maxError_opti = maxError;
rmsFB_opti    = rmsFB;

load('monteCarlo_5.mat')



%% plot results
clear ha
%figure settings
colors = [0,      0.4470, 0.7410;
          0.8500, 0.3250, 0.0980;
          0.9290, 0.6940, 0.1250;
          0.4940, 0.1840, 0.5560];
%Font size
fontSize   = 8;
labelSize  = 9;
legendSize = 8;

% Calculate mean, max and min values
% no optimized spectral points
D = [0,4:2:30];
meanRmsError = mean(rmsError,2);
maxRmsError  = max(rmsError,[],2);
minRmsError  = min(rmsError,[],2);

meanMaxError = mean(maxError,2);
maxMaxError  = max(maxError,[],2);
minMaxError  = min(maxError,[],2);

meanRmsFB    = mean(rmsFB,2);
maxRmsFB     = max(rmsFB,[],2);
minRmsFB     = min(rmsFB,[],2);

% optimized spectral points
meanRmsError_opti = mean(rmsError_opti,2);
maxRmsError_opti  = max(rmsError_opti,[],2);
minRmsError_opti  = min(rmsError_opti,[],2);

meanMaxError_opti = mean(maxError_opti,2);
maxMaxError_opti  = max(maxError_opti,[],2);
minMaxError_opti  = min(maxError_opti,[],2);
 
meanRmsFB_opti    = mean(rmsFB_opti,2);
maxRmsFB_opti     = max(rmsFB_opti,[],2);
minRmsFB_opti     = min(rmsFB_opti,[],2);

%% Add for D=0
meanRmsError_opti = [meanRmsError(1); meanRmsError_opti];
meanMaxError_opti = [meanMaxError(1); meanMaxError_opti];
meanRmsFB_opti    = [meanRmsFB(1); meanRmsFB_opti];

maxRmsError_opti = [maxRmsError(1); maxRmsError_opti];
maxMaxError_opti = [maxMaxError(1); maxMaxError_opti];
maxRmsFB_opti    = [maxRmsFB(1);    maxRmsFB_opti];

minRmsError_opti = [minRmsError(1); minRmsError_opti];
minMaxError_opti = [minMaxError(1); minMaxError_opti];
minRmsFB_opti    = [minRmsFB(1);    minRmsFB_opti];
%

%% PLot results
% NO OPTIMIZED SPECTRAL POINTS
plot4 = figure(4); clf(plot4);
set(gcf,'Color','w')
ha(1,1) = subplot(3,1,1);
set(gca,'FontSize',fontSize);
hold on
errorbar(D,meanRmsError/(1e-3),...
            abs(minRmsError-meanRmsError)/(1e-3), ...
            abs(maxRmsError-meanRmsError)/(1e-3),...
            'LineWidth',1)
plot([0 30],[0.039,0.039],':k')
ylim([0 19]*1e-2)
xlim([0 31])
ylabel('(mrad)','Interpreter','Latex','FontSize',labelSize)
legend('RMS error','Interpreter','Latex','FontSize',legendSize)

ha(2,1) = subplot(3,1,2)
set(gca,'FontSize',fontSize);
hold on
errorbar(D,meanMaxError/(1e-3),...
    abs(minMaxError-meanMaxError)/(1e-3),...
    abs(maxMaxError-meanMaxError)/(1e-3),...
    'LineWidth',1,'Color',colors(2,:))
plot([0 30],[0.24,0.24],':k')
ylabel('(mrad)','Interpreter','Latex','FontSize',labelSize)
legend('Max. error','Interpreter','Latex','FontSize',legendSize)
ylim([0.15 1.4])
xlim([0 31])
hold off
%

ha(3,1) = subplot(3,1,3)
set(gca,'FontSize',fontSize);
hold on
errorbar(D,meanRmsFB,...
    abs(minRmsFB-meanRmsFB),...
    abs(maxRmsFB-meanRmsFB),...
    'LineWidth',1,'Color',colors(3,:))
plot([0 30],[7.194,7.194],':k')
xlabel('Number of spectral points, $D$','Interpreter','Latex','FontSize',labelSize)
ylabel('(mA)','Interpreter','Latex','FontSize',labelSize)
legend('RMS FB','Interpreter','Latex','FontSize',legendSize)
%ylim([3 19]*1e-2)
xlim([0 31])
hold off

[plot4 ha] = subplots(plot4,ha,'gabSize',[0.09, 0.03])
set(gcf,'PaperSize',[8.4 8.4],'PaperPosition',[0+0.1 0 8.4 8.4])

clear ha
% WITH OPTIMIZED SPECTRAL POINTS
plot5 = figure(5); clf(plot5);
set(gcf,'Color','w')
ha(1,1) = subplot(3,1,1);
set(gca,'FontSize',fontSize);
hold on
errorbar(D,meanRmsError_opti/(1e-3),...
            abs(minRmsError_opti-meanRmsError_opti)/(1e-3), ...
            abs(maxRmsError_opti-meanRmsError_opti)/(1e-3),...
            'LineWidth',1)
plot([0 30],[0.039,0.039],':k')
ylim([0 19]*1e-2)
xlim([0 31])
ylabel('(mrad)','Interpreter','Latex','FontSize',labelSize)
legend('RMS error','Interpreter','Latex','FontSize',legendSize)

ha(2,1) = subplot(3,1,2)
set(gca,'FontSize',fontSize);
hold on
errorbar(D,meanMaxError_opti/(1e-3),...
    abs(minMaxError_opti-meanMaxError_opti)/(1e-3),...
    abs(maxMaxError_opti-meanMaxError_opti)/(1e-3),...
    'LineWidth',1,'Color',colors(2,:))
plot([0 30],[0.24,0.24],':k')
ylabel('(mrad)','Interpreter','Latex','FontSize',labelSize)
legend('Max. error','Interpreter','Latex','FontSize',legendSize)
ylim([0.15 1.4])
xlim([0 31])
hold off
%

ha(3,1) = subplot(3,1,3)
set(gca,'FontSize',fontSize);
hold on
errorbar(D,meanRmsFB_opti,...
    abs(minRmsFB_opti-meanRmsFB_opti),...
    abs(maxRmsFB_opti-meanRmsFB_opti),...
    'LineWidth',1,'Color',colors(3,:))
plot([0 30],[7.194,7.194],':k')
xlabel('Number of spectral points, $D$','Interpreter','Latex','FontSize',labelSize)
ylabel('(mA)','Interpreter','Latex','FontSize',labelSize)
legend('RMS FB','Interpreter','Latex','FontSize',legendSize)
%ylim([3 19]*1e-2)
xlim([0 31])
hold off

[plot5 ha] = subplots(plot5,ha,'gabSize',[0.09, 0.03])
set(gcf,'PaperSize',[8.4 8.4],'PaperPosition',[0+0.1 0 8.4 8.4])

%% Save Figure
%saveas(plot1,fullfile(pwd,'Images','rmsError_D.pdf'))
%saveas(plot2,fullfile(pwd,'Images','maxError_D.pdf'))
%saveas(plot3,fullfile(pwd,'Images','rmsFB_D.pdf'))
saveas(plot4,fullfile(pwd,'Images','all_D.pdf'))
saveas(plot5,fullfile(pwd,'Images','all_D_opti.pdf'))


pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
%}