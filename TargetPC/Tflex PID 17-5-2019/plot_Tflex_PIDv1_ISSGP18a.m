t = controlOutputs.time;

FB = controlOutputs.signals(1);
FF = controlOutputs.signals(2);

figure(11);clf(11);
ha(1) = plot(t,FB.values(:));
hold on
ha(2) = plot(t,FF.values(:));
legend(ha,FB.label,FF.label)
