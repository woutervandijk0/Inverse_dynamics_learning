clc, clear all

x = linspace(4,30,2000);

%% Prior
mu_p = 10;
mu_l = 15
s_p  = 2;
s_l  = 1.5;

mu_po = (s_p^(-2)*mu_p + s_l^(-2)*mu_l)/(s_p^(-2)+s_l^(-2));
s_po  = sqrt(s_p^2*s_l^2/(s_p^2+s_l^2));

prior = gaussianDistr(x,mu_p,s_p);
lik = gaussianDistr(x,mu_l,s_l);
post = gaussianDistr(x,mu_po,s_po);

%% Plot
% Some figure settings
fontSize   = 12;
labelSize  = 15;
titleSize  = 15;
legendSize = 12;

postDistr_1 = figure(1),clf(postDistr_1)
set(gcf,'Color','White')
hold on
plot(x,prior,'k');
%plot(x,lik,'-k','LineWidth',1)
%plot(x,post,'-.k','LineWidth',1)
%legend('Prior','Likelihood','Posterior','Interpreter','Latex')
legend('$P(\mathbf{f}|\theta)$','$P(\mathbf{y}|\mathbf{f},\theta)$','$P(\mathbf{f}|\mathbf{y},\theta)$','Interpreter','Latex')
hold off
set(gcf,'PaperSize',[8.4 8.4/2],'PaperPosition',[0 0.1 8.4 8.4/2])
set(gca,'YTickLabel','','XTickLabel','')
ha(1) = gca;

postDistr_2 = figure(2),clf(postDistr_2)
set(gcf,'Color','White')
hold on
plot(x,prior,'k');
plot(x,lik,'-k','LineWidth',1)
%plot(x,post,'-.k','LineWidth',1)
%legend('Prior','Likelihood','Posterior','Interpreter','Latex')
legend('$P(\mathbf{f}|\theta)$','$P(\mathbf{y}|\mathbf{f},\theta)$','$P(\mathbf{f}|\mathbf{y},\theta)$','Interpreter','Latex')
hold off
set(gcf,'PaperSize',[8.4 8.4/2],'PaperPosition',[0 0.1 8.4 8.4/2])
set(gca,'YTickLabel','','XTickLabel','')
ha(2) = gca;


postDistr_3 = figure(3),clf(postDistr_3)
set(gcf,'Color','White')
hold on
plot(x,prior,'k');
plot(x,lik,'-k','LineWidth',1)
plot(x,post,'-.k','LineWidth',1)
%legend('Prior','Likelihood','Posterior','Interpreter','Latex')
legend('$P(\mathbf{f}|\theta)$','$P(\mathbf{y}|\mathbf{f},\theta)$','$P(\mathbf{f}|\mathbf{y},\theta)$','Interpreter','Latex')
hold off
set(gcf,'PaperSize',[8.4 8.4/2],'PaperPosition',[0 0.1 8.4 8.4/2])
set(gca,'YTickLabel','','XTickLabel','')
ha(3) = gca;


linkaxes(ha,'y')

%%
saveas(postDistr_1,fullfile(pwd,'Images','postDistr_1.pdf'))
saveas(postDistr_2,fullfile(pwd,'Images','postDistr_2.pdf'))
saveas(postDistr_3,fullfile(pwd,'Images','postDistr_3.pdf'))


    pdf2ipepdf_v2(fullfile(pwd,'Images'),{''},{''})



%% Function Normal distributions
function [f] = gaussianDistr(x,mu,s)
    p1 = -.5 * ((x - mu)/s) .^ 2;
    p2 = (s * sqrt(2*pi));
    f = exp(p1) ./ p2;
end