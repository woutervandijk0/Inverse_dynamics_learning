clc, clear all%, close all

saveFig = 1;

basePath = 'C:\Users\wout7\OneDrive - student.utwente.nl\ME - Master\Thesis\Data\TFlex\';
addpath(basePath)
fileID_1 = 'Training\TRAIN_long_withSopti.DAT';
fileID_2 = 'Error\ERROR_long_withSopti.DAT';
N        = length(SimulinkRealTime.utils.getFileScopeData(fileID_1).data);
interval = 80000:(N-1);
ts       = 1/1000;
t        = 60+[1:length(interval)]*ts;
DATA     = SimulinkRealTime.utils.getFileScopeData([basePath,fileID_1]).data(interval,:);
DATA2    = SimulinkRealTime.utils.getFileScopeData([basePath,fileID_2]).data(interval,:);
xTrain   = DATA(:,1:3);
FB       = DATA2(:,3);


fpass = 50;     % [Hz] Passband frequency
FB = lowpass(FB,fpass,1/ts);
xTrain = lowpass(xTrain,fpass,1/ts);

%% 
colors = [0,      0.4470, 0.7410;
          0.8500, 0.3250, 0.0980;
          0.9290, 0.6940, 0.1250;
          0.4940, 0.1840, 0.5560];
fontSize  = 8;
labelSize = 12;


figID = figure(1),clf(figID)
ha(1,1) =  subplot(4,1,1);
set(gca,'FontSize',fontSize);
hold on
plot(t,xTrain(:,1),'Color',colors(1,:))
ylabel('$r$ (rad)','Interpreter','Latex','FontSize',labelSize)
xlim([60,90])
hold off

ha(2,1) =  subplot(4,1,2);
set(gca,'FontSize',fontSize);
hold on
plot(t,xTrain(:,2),'Color',colors(2,:))
ylabel('$\dot{r}$ (rad/s)','Interpreter','Latex','FontSize',labelSize)
xlim([60,90])
hold off

ha(3,1) =  subplot(4,1,3);
set(gca,'FontSize',fontSize);
hold on
plot(t,xTrain(:,3),'Color',colors(3,:))
ylabel('$\ddot{r}$ (rad/$\mathrm{s}^2$) ','Interpreter','Latex','FontSize',labelSize)
xlim([60,90])
hold off

ha(4,1) =  subplot(4,1,4);
set(gca,'FontSize',fontSize);
hold on
plot(t,FB,'Color',colors(4,:))
ylabel('$u_{FB}$ (mA)','Interpreter','Latex','FontSize',labelSize)
xlabel('t (s)','Interpreter','Latex','FontSize',labelSize)
xlim([60,95])
hold off

[figID,ha] = subplots(figID,ha,'gabSize',[0.09, 0.04]);
set(gcf,'PaperSize',[8.4 12],'PaperPosition',[0 0 8.4 12])
%% Save figure;
if saveFig == 1
    saveas(figID,fullfile(pwd,'Images','TrainingDataset.pdf'))
    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
end

%%
xTraining = xTrain;
yTraining = FB;

