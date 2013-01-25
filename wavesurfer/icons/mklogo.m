N=1024

x=(0:N-1)/N;
nper=24;

y0=sin(x*2*pi*nper);
s=0.1
ox=[0.0 0.3-s 0.3+s 0.5-s 0.5+s 0.7 1];
oy=[0.0 0.0  -1   0    -1   0   0];
ox=[0 3-s 3+s 4-s 4+s 5-s 5+s 6-s 6+s 7-s 7+s 8]/8;
oy=[0 0   -.5 .5  0   0   -.5 .7  .7  0   0   0];
o=interp1(ox,oy,x,'linear');
ax=[0 2-s 2+s 3-s 3+s 4-s 4+s 5-s 5+s 6-s 6+s 7-s 7+s 8]/8;
ay=[0 .1   1   1   .4  .4  1   1   .4  .5  .2 .1   .1  0];
a=interp1(ax,ay,x,'linear');


y=1*a.*y0+o;


plot(x,y);

