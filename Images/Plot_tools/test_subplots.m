

t = linspace(0,20,200);
y = sind(50*pi*t)

fig101 = figure(101),clf(101)
han(1,1) = subplot(2,2,1);
plot(t,y)
ylabel('(1,1)')

han(1,2) = subplot(2,2,2);
plot(t,y)
ylabel('(1,2)')

han(2,1) = subplot(2,2,3);
plot(t,y)
ylabel('(2,1)')

han(2,2) = subplot(2,2,4);
plot(t,y)
ylabel('(2,2)')

[fig101,han] = subplots(fig101,han)