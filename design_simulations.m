addpath('M:\projects\sustained\local\lib\toolboxes\spm12')
spm
%%
block = 1;
TR=2.336;
 maxT = ceil(390./TR)*TR;

 
%onset times for first task (in s)
%What should the onset times for the first stimulus be?
 
blocklength = 16;
breaklength = 10;


deltaT = 0.01;%25;
hrf_25=spm_hrf(deltaT);

t1 = [1:2*(blocklength+breaklength):maxT-(blocklength+breaklength)*2];
% t1 = t1(1:8);

t2=t1+blocklength+breaklength;  

 
t=0:deltaT*TR:maxT;

r1 = zeros(1,size(t,2));  %I'm assuming time resoultion of .25 s
r2 = r1;


for i=1:length(t1)
    % pure block design
    if block == 1
    r1(t1(i)<=t & t<=(t1(i)+blocklength))=1;  %add 2 for a 2s trial
    r2(t2(i)<=t & t<=(t2(i)+blocklength))=1;  %add 2 for a 2s trial
    else
    % slightly adapted block design
    for k = 1:2:blocklength
    r1(t1(i)+k<=t & t<=(t1(i)+k+1))=1;  %add 2 for a 2s trial
    r2(t2(i)+k<=t & t<=(t2(i)+k+1))=1;  %add 2 for a 2s trial
    end
    end
end
% figure,plot(t,r1(1:length(t))),hold all,plot(t,r2(1:length(t)))
%
r1=conv(hrf_25, r1);
r2=conv(hrf_25, r2);
% 

r1=r1(1:TR/deltaT:size(t,2));
r2=r2(1:TR/deltaT:size(t,2)); 
t_tr=t(1:TR/deltaT:end);  %this is time in seconds (for plotting purposes)
%  t_tr = t;
 
r1=r1-mean(r1);
r2=r2-mean(r2);
 
 figure
plot(t_tr, r1,'o-')
hold on
plot(t_tr, r2, 'go-')
hold off
ylim([-0.2 1.2])
title(sprintf('block:%i   TR:%.2f   block:%.1f   break:%.1f   deltaT:%.3f',block,TR,blocklength,breaklength,deltaT))
 %
%efficiency for each regressor, the difference and all together
X=[r1', r2'];
c1=[1 0];
c2=[0 1];
 
eff1=1./(c1*inv(X'*X)*c1');
 
eff2=1./(c2*inv(X'*X)*c2');
 
 
 
eff_all=2./(c1*inv(X'*X)*c1'+c2*inv(X'*X)*c2');
 
fprintf('block: %i \t %.1f \t %.1f \t %.1f\n',block,eff1,eff2,eff_all)


