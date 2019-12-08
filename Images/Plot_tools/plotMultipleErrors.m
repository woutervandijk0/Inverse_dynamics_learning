clc, clear all, close all

load('ErrorD21.mat')
xTrainD21 = xTrain;
yTrainD21 = yTrain;
errorD21  = error;

load('ErrorD150.mat')
xTrainD150 = xTrain;
yTrainD150 = yTrain;
errorD150  = error;

ts = 1/1000;
N = length(xTrainD150);
t = [0:N-1]*ts;


%%
fontSize    = 20;        % Default: plot dataset
tSwitch = [50-9 50+9];
yLim    = [-5e-3 5e-3]

errorPlot = figure(1); clf(errorPlot);
han(1,1) = subplot(2,1,1);
hold on
set(gca,'FontSize',fontSize-3)
plot(t,xTrainD21(:,1)*pi/180)
ylabel('Angle (rad)')
%title(titleString,'Interpreter','Latex','FontSize',fontSize);
ylabel('Setpoint (rad)','Interpreter','Latex','FontSize',fontSize);
hold on

han(2,1) = subplot(2,1,2);
set(gca,'FontSize',fontSize-3)
hold on
plot(t,errorD21*pi/180)
plot([tSwitch(1),tSwitch(1)],[yLim(1),yLim(2)],'--k','LineWidth',1.5)
plot([tSwitch(2),tSwitch(2)],[yLim(1),yLim(2)],'--k','LineWidth',1.5)
ylabel('Error (rad)','Interpreter','Latex','FontSize',fontSize);
xlabel('time (s)','Interpreter','Latex','FontSize',fontSize)
hold off

[errorPlot ,han] = subplots(errorPlot,han,'gabSize',[0.09, 0.08]);

%%     
saveas(errorPlot,fullfile(pwd,'Images','ErrorD21.pdf'))
pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})
