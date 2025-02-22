%%
clc;
clear;
close all;
disp('*******************************************************************')
oldfolder=cd;
cd(oldfolder);
addpath('Data');
addpath('Miscellaneous');
%% 
disp('-----------------------TRAIN STATES MACHINE---------------------')
ds=tabularTextDatastore("Box.csv");
T=readall(ds);
T(:,1)=[];
Bt=T{:,:};
Xg=Bt(:,1:end-1);
yb=Bt(:,end);
train_size = floor(length(Bt) * 0.7);
X_train = Xg(1:train_size,:) ;
X_test = Xg(train_size+1:end,:) ;

y_train=yb(1:train_size,:);
y_test=yb(train_size+1:end,:);


X = tonndata(X_train,false,false);

T = tonndata(y_train,false,false);

% Choose a Training Function
% For a list of all training functions type: help nntrain
% 'trainlm' is usually fastest.
% 'trainbr' takes longer but may be better for challenging problems.
% 'trainscg' uses less memory. Suitable in low memory situations.
trainFcn = 'trainlm';  % Levenberg-Marquardt backpropagation.

% Create a Nonlinear Autoregressive Network with External Input
inputDelays = 1:30;
feedbackDelays = 1:3;
hiddenLayerSize = 30;
net = narxnet(inputDelays,feedbackDelays,hiddenLayerSize,'open',trainFcn);

% Prepare the Data for Training and Simulation
% The function PREPARETS prepares timeseries data for a particular network,
% shifting time by the minimum amount to fill input states and layer
% states. Using PREPARETS allows you to keep your original time series data
% unchanged, while easily customizing it for networks with differing
% numbers of delays, with open loop or closed loop feedback modes.
[x,xi,ai,t] = preparets(net,X,{},T);
%[ed,ei,ci,w] = preparets(net,Y,{},D);

% Setup Division of Data for Training, Validation, Testing
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 5/100;

% Train the Network
[net,tr] = train(net,x,t,xi,ai);

% Test the Network
y = net(x,xi,ai);
%prediction_of_test=net(ed,ei,ci); 
e = gsubtract(t,y);
performance = perform(net,t,y);

% View the Network
view(net)

% Plots
% Uncomment these lines to enable various plots.
figure, plotperform(tr)
figure, plottrainstate(tr)
figure, ploterrhist(e)
figure, plotregression(t,y)
figure, plotresponse(t,y)
figure, ploterrcorr(e)
figure, plotinerrcorr(x,e)

% Closed Loop Network
% Use this network to do multi-step prediction.
% The function CLOSELOOP replaces the feedback input with a direct
% connection from the outout layer.
netc = closeloop(net);
netc.name = [net.name ' - Closed Loop'];
view(netc)
[xc,xic,aic,tc] = preparets(netc,X,{},T);
yc = netc(xc,xic,aic);
closedLoopPerformance = perform(net,tc,yc);

% Step-Ahead Prediction Network
% For some applications it helps to get the prediction a timestep early.
% The original network returns predicted y(t+1) at the same time it is
% given y(t+1). For some applications such as decision making, it would
% help to have predicted y(t+1) once y(t) is available, but before the
% actual y(t+1) occurs. The network can be made to return its output a
% timestep early by removing one delay so that its minimal tap delay is now
% 0 instead of 1. The new network returns the same outputs as the original
% network, but outputs are shifted left one timestep.
nets = removedelay(net);
nets.name = [net.name ' - Predict One Step Ahead'];
view(nets)
[xs,xis,ais,ts] = preparets(nets,X,{},T);
ys = nets(xs,xis,ais);
stepAheadPerformance = perform(nets,ts,ys);


y2 = nets(cell(0,220),xis,ais);

figure()
plot(cell2mat(y2))
hold on
plot(y_test(1:20,:))


% [y a]=lpredict(X_train,510, size(X_test,1));
% figure(1)
% for i=1:size(y,2)
% subplot(3,3,i)
% plot(X_test(:,i),'r','LineWidth',1)
% hold on
% plot(y(:,i) ,'b','LineWidth',1)
% hold off
% xlabel('Time','FontName','Helvetica', 'Fontsize', 9);
% ylabel('Temperature','FontName','Helvetica', 'Fontsize', 9);
% title( strcat('X', sprintf('%d',i)),...
%     'FontName','Helvetica', 'Fontsize', 9)
% legend('True model','Self Forecast',...
%     'location','northeast');
% set(gca, 'FontName','Helvetica', 'Fontsize', 9)
% set(gcf,'color','white')  
% end