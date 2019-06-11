function [Xsp] = loadSp(dataID)
    datafolder = 'C:\Users\wout7\OneDrive - student.utwente.nl\ME - Master\Thesis\Data\InverseDynamics\';
    idString = dataID(1:end-4);
    setpointID = [idString,'sp.mat'];
    fullString = [datafolder,setpointID];
    load(fullString);
    %Xsp(:,2) = Xsp(:,2)*1e3;
    %Xsp(:,3) = Xsp(:,3)*1e6;
end