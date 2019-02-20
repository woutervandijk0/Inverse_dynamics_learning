%%% Plot simulated train data


%{
%input_train
t = target_train.Time(:);
indi = find(t>1e-2);
indi = indi(1:end-10);
t = t(indi);
T1 = target_train.Data(indi,1);
T2 = target_train.Data(indi,2);
q_1 = input_train.Data(indi,1);
q_2 = input_train.Data(indi,2);

figure(1),clf(1);
subplot(2,1,1)
plot(t,q_1,t,q_2,'LineWidth',1.5)
legend('$q_1$','$q_2$','interpreter','latex','FontSize',15)
%ylim([-1 1])

subplot(2,1,2)
plot(t,T1,t,T2,'LineWidth',1.5)
legend('$T_2 - \hat{T}_2$','$T_2 - \hat{T}_2$','interpreter','latex','FontSize',15)
%ylim([-1 1])
%}
%% Plot memory storage - v2
tic
figure(4),clf(4)
subplot(4,1,1)
ylabel('$\theta_1$','Interpreter','Latex')
subplot(4,1,2)
ylabel('$\theta_2$','Interpreter','Latex')
subplot(4,1,3)
ylabel('$T_1-\hat{T}_1$','Interpreter','Latex','FontSize',10)
subplot(4,1,4)
ylabel('$T_2-\hat{T}_2$','Interpreter','Latex','FontSize',10)
xlabel('time $[s] \rightarrow$','Interpreter','Latex','FontSize',10)

N_store = input_vector.Time(end)/ts_store;      % Number of times values were stored
ts_ratio = ts_store/ts;                         % Ratio between sample times
t_window = (Z-1)*ts_store;                      % domain of drifting window
stepSize = 10;                                  % Speed of animation
indi = sort(randi([1,Z],1,M));

%% Define GP
N_search = 20;    %Max iterations of gradient descent
iN = 6;         %Input dimensions
cov = {@covSEard}; sf = 2; ell = 1.0; hyp.cov = log([ell*ones(iN,1);sf]);
mean = @meanZero;% hyp.mean = 0;
sn = 0.5
lik = {@likGauss};    hyp.lik = log(sn); 
inf = @infGaussLik;
load('inputs.mat')
xu = X(:,indi)';
cov = {'apxSparse',cov,xu};
hyp.xu = xu;

%% Run simulation data
for t_indi = 1:stepSize:N_store
    t_cur = t_indi*ts_store;                % Current time
    t = t_cur+[-t_window:ts_store:0];       % current drifting time window
    %Set time window at start of simulation
    if t_cur-ts_store*(Z-1) < 0 
        t = [zeros(1,(Z-1)-t_indi), 0:ts_store:t_cur];
    end
    t_lim = [t_cur-(t_window+1) t_cur+1];   % X-axis limits for plotting
    
    ts_index = round(t_indi*ts_ratio);
    X = squeeze(input_vector.Data(:,:,ts_index));
    y = squeeze(output_vector.Data(:,:,ts_index));
    xs = X;
    
    %Hyperparameter optimization & pseudo input search
    %hyp = minimize(hyp,@gp,-N_search,inf,mean,cov,lik,X',y(1,:)');
    
    % Conditioning
    infv  = @(varargin) inf(varargin{:},struct('s',0.0));           % VFE, opt.s = 0
    hyp = minimize(hyp,@gp,-N_search,infv,mean,cov,lik,X',y(1,:)');
    
    [ymuv,ys2v] = gp(hyp,infv,mean,cov,lik,X',y(1,:)',xs');
    %infs = @(varargin) inf(varargin{:},struct('s',0.1));           % SPEP, 0<opt.s<1
    %[ymus,ys2s] = gp(hyp,infs,mean,cov,lik,X',y(1,:)',xs');
    %inff = @(varargin) inf(varargin{:},struct('s',1.0));           % FITC, opt.s = 1
    %[ymuf,ys2f] = gp(hyp,inff,mean,cov,lik,X',y(1,:)',xs');
    
    % Training Input - Displacement
    subplot(4,1,1)
    plot(t,X(1,:),'r');
    hold on
    %scatter(t(indi),X(1,indi),'rx');
    plot(t,X(2,:),'b');
    hold off
    ylim([-0.2 0.2]);
    xlim( t_lim );
    title(['Time: ',num2str(round(t_cur)),' s']);
    ylabel('$\theta$','Interpreter','Latex');
    
    % Velocity
    subplot(4,1,2);
    plot(t,X(3,:),'r');
    hold on
    plot(t,X(4,:),'b');
    hold off
    xlim( t_lim );
    ylabel('$\dot{\theta}$','Interpreter','Latex');
    
    % Acceleration
    subplot(4,1,3)
    plot(t,X(5,:),'r');
    hold on
    plot(t,X(6,:),'b');
    hold off
    xlim( t_lim );
    ylabel('$\ddot{\theta}$','Interpreter','Latex');
    
    % Training Output
    subplot(4,1,4)
    plot(t,y(2,:),'b');
    hold on
    plot(t,y(1,:),'r');
    plot(t,ymuv,'k--')
    hold off
    ylim([-pi pi]/10);
    xlim( t_lim );
    ylabel('$T_2-\hat{T}_2$','Interpreter','Latex','FontSize',10);
    xlabel('time $[s] \rightarrow$','Interpreter','Latex','FontSize',10);
    
    drawnow
    
%     % sparse GP_regression  
%     likfunc = @likGauss; sn = 0; hyp.lik = log(sn);
%     %inf = @(varargin) infGaussLik(varargin{:}, struct('s', 0.0));
%     
%     mean = @meanZero;
%     covfunc = {@apxSparse, {@covSEard}, X(:,indi)};
%     %hyp2.cov = [log(2)*ones(N*3,1);log(0.1)]';
%     hyp2.cov = [0;log(0.1)];
%     %hyp2.lik = log(0.1);
%     hyp2.xu = X(:,indi);
%     %hyp2 = minimize(hyp2, @gp, -100, inf, meanfunc, covfuncF, likfunc, X', y(1,:)');
%     
%     inf = @infGaussLik
%     infv  = @(varargin) inf(varargin{:},struct('s',0.0));
%     [ymuv,ys2v] = gp(hyp2,infv,mean,cov,lik,x,y,xs);
%     [mF s2F] = gp(hyp2, infv, mean, covfunc, likfunc, X(1,:)', y(1,:)');
    
    % Update inducing points
    indi = indi-stepSize;
    indi_r = size(find(indi<1),2);
    indi = [indi(indi_r+1:end),Z+indi(1:indi_r)];
    
    N_search = max(N_search/2,2);
end
toc