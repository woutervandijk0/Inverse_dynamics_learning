
addpath('C:\Users\wout7\OneDrive - student.utwente.nl\ME - Master\Thesis\Data\TFled')
fileID = 'DATA.DAT';

simdata = SimulinkRealTime.utils.getFileScopeData(fileID);
simdata.signalNames

%p = simdata.data(:,1);
%figure(1),clf(1)
%plot(p)