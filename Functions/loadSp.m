function [Xsp] = loadSp(dataID)
    idString = dataID(1:end-4);
    setpointID = [idString,'sp.mat'];
    load(setpointID);
    %Xsp(:,2) = Xsp(:,2)*1e3;
    %Xsp(:,3) = Xsp(:,3)*1e6;
end