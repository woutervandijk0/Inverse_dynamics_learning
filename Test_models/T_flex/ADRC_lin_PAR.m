s = tf('s');
P = 5/(5*(0.2*s^2 + 0.2292*s+11.36));
%P = 1/s^2;
[Pnum,Pden] = tfdata(P,'v');

%%
ts = 0.001;
h = 1*ts;
% B01 = 1;
% B02 = 1/(2*h^0.5);
% B03 = 2/(5^2 *h^1.2);
%alpha = 1;
%delta = 1;
h0 = 0.010;%40*0.001;
b0 = 0.2; %staat dit niet verkeerd om in de simulatie?
r0 = 100;
r = 5000;
c=1;
a1 = 0.5;
a2 = 0.25;
d = 0.01;

%b3 = 1;%2000;
%b2 = 1/(2*sqrt(h));%1000;
%b1 = 2/(25*h^1.2);%200;

ctra1 = 0.6;%0.6
ctra2 = 0.4;%0.4
ctrb1 = 50;%50
ctrb2 =2;%2

%% Classic PD gains
ctrb1 = 55%250;%50
ctrb2 =1%2;%2
%% system
%h=0.004
b1 = 1100;%1000;%2000;
b2 = 60000;%8500;%1000;
b3 = 30000;%12500;%200;
%%
%h=0.004
b0=0.2;
b1 = 1800;%2000;
b2 = 150000;%1000;
b3 = 220000%90000;%200;
%%
%h=0.004
b0=0.2;
b1 = 1000;
b2 = 60000;
b3 = 40000;
%%
%h=0.004
b0=0.2;
b1 = 800;%2000;
b2 = 60000;%1000;
b3 = 40000%90000;%200;
%% does not go to 1
%h=0.004
b1 = 200;
b2 = 1000;
b3 = 2000;

%% 
w0 = 50*2*pi
b1 = 9*w0;
b2 = 3*w0^2;%3*w0^2;
b3 = w0^3;

%% works with m/s^2
h = 0.001;
b0=5;
b1 = 1/h;
b2 = 1/(2*sqrt(h))/h^1;
b3 = 1/(5^2 *h^(1.2))/h^1;

%% works with m/s^2
h = 0.001;
b1 = 1/h^1
b2 = 1/(8*sqrt(h^2))/h^1%3*w0^2;
b3 = 2/(10^2 *h^(1.2))/h^1;

%% linear observer
b1=1;
b2 = 1/(3*h);
b3 = 2/(8^2 *h^2);


%% second order ADRC
B1 = 2*W0;
B2 = W0^2;
Kp = Wc;

%% Thirth order ADRC
B1 = 3*W0;
B2 = 3*W0^2;
B3 = W0^3;
Kp = Wc^2;
Kd = 2*Wc;

%% fourth order ADRC
B1 = 4*W0;
B2 = 6*W0^2;
B3 = 4*W0^3;
B4 = W0^4;
Kp = Wc^3;
Kd = 3*Wc^2;
Kdd = 3*Wc;


%use trapezoidal reference signal

%% test
b0 = 5;
h = 0.001;
b1 = 1/h^1
b2 = 1/(8*sqrt(h^2))/h^1%3*w0^2;
b3 = 2/(10^2 *h^(1.2))/h^1;
ctrb1 = 10;
%% Thirth order ADRC
W0 = 70*2*pi;
Wc = 10*2*pi;
b1 = 3*W0;
b2 = 3*W0^2;
b3 = W0^3;
ctrb1 = Wc^2;
ctrb2 = 2*Wc;