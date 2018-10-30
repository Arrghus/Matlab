% Marks New interpolation operators
% 6th order accurate (diagonal norm) 
% M=19 is the minimum amount of points on the coarse mesh

function [I1,I2] = Interpolation_6(M_C)

M_F=M_C*2-1;

% Coarse to fine
I1=zeros(M_F,M_C);

t1=    [6854313/6988288 , 401925/6988288 , -401925/6988288 ...
      , 133975/6988288 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0  ; ...
    560547/1537664 , 1201479/1537664 , -240439/1537664 ...
      , 16077/1537664 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ; ...
    203385/5552128 , 1225647/1388032 , 364155/2776064 ...
      , -80385/1388032 , 39385/5552128 , 0 , 0 , 0 , 0 , 0 , 0 , 0  ; ...
    -145919/2743808 , 721527/1371904 , 105687/171488 , ...
      -25/256 , 23631/2743808 , 0 , 0 , 0 , 0 , 0 , 0 , 0  ; ...
    -178863/4033024 , 1178085/8066048 , ...
      1658587/2016512 , 401925/4033024 , -15/512 , ...
      43801/8066048 , 0 , 0 , 0 , 0 , 0 , 0 ; ...
    -1668147/11213056 , 4193225/11213056 , ...
      375675/2803264 , 2009625/2803264 , ...
      -984625/11213056 , 3/256 , 0 , 0 , 0 , 0 , 0 , 0 ; ...
    -561187/2949120 , 831521/1474560 , -788801/1474560 ...
      , 412643/368640 , 39385/589824 , -43801/1474560 ...
      , 5/1024 , 0 , 0 , 0 , 0 , 0 ; ...
    23/1024 , 23/147456 , -43435/221184 , ...
      26795/36864 , 39385/73728 , -43801/442368 , ...
      3/256 , 0 , 0 , 0 , 0 , 0  ; ...
    79379/368640 , -1664707/2949120 , 284431/737280 , ...
      26795/294912 , 606529/737280 , 43801/589824 , ...
      -15/512 , 5/1024 , 0 , 0 , 0 , 0 ; ...
    3589/27648 , -2225/6144 , 22939/73728 , ...
      -26795/221184 , 39385/73728 , 43801/73728 , ...
      -25/256 , 3/256 , 0 , 0 , 0 , 0 ; ...
    -720623/14745600 , 10637/92160 , -89513/1474560 , ...
      -5359/147456 , 39385/589824 , 3372677/3686400 , ...
      75/1024 , -15/512 , 5/1024 , 0 , 0 , 0 ; ...
    -6357/81920 , 55219/276480 , -8707/61440 , ...
      5359/368640 , -39385/442368 , 43801/73728 , ...
      75/128 , -25/256 , 3/256 , 0 , 0 , 0 ; ...
    -13315/884736 , 2589/65536 , -479/16384 , ...
      5359/884736 , -7877/294912 , 43801/589824 , ...
      231/256 , 75/1024 , -15/512 , 5/1024 , 0 , 0  ; ...
    8299/737280 , -7043/245760 , 5473/276480 , 0 , ...
      7877/737280 , -43801/442368 , 75/128 , ...
      75/128 , -25/256 , 3/256 , 0 , 0 ; ...
    11027/2949120 , -8461/884736 , 655/98304 , 0 , ...
      7877/1769472 , -43801/1474560 , 75/1024 , ...
      231/256 , 75/1024 , -15/512 , 5/1024 , 0 ; ...
    -601/614400 , 601/245760 , -601/368640 , 0 , 0 , ...
      43801/3686400 , -25/256 , 75/128 , ...
      75/128 , -25/256 , 3/256 , 0 ; ...
    -601/1474560 , 601/589824 , -601/884736 , 0 , 0 , ...
      43801/8847360 , -15/512 , 75/1024 , ...
      231/256 , 75/1024 , -15/512 , 5/1024 ] ;
  
  t2=  [5/1024 , -15/512 , 75/1024, 231/256 , 75/1024 , -15/512 , 5/1024];
      
  t3=  [3/256 , -25/256 , 75/128 , 75/128 , -25/256 , 3/256];     

I1(1:17,1:12)=t1;
I1(M_F-16:M_F,M_C-11:M_C)=fliplr(flipud(t1));
I1(18,7:12)=t3;
for i=19:2:M_F-18
    j=(i-3)/2;
    I1(i,j-1:j+5)=t2;
    I1(i+1,j:j+5)=t3;
end

% Fine to coarse
I2=zeros(M_C,M_F);

t1=[6854313/13976576 , 2802735/3494144 , ...
      1016925/27953152 , -729595/6988288 , ...
      -894315/13976576 , -1668147/6988288 , ...
      -8417805/27953152 , 15525/436768 , ...
      1190685/3494144 , 89725/436768 , ...
      -2161869/27953152 , -858195/6988288 , ...
      -332875/13976576 , 124485/6988288 , ...
      165405/27953152 , -5409/3494144 , -9015/13976576;  ...
    80385/12301312 , 1201479/3075328 , 1225647/6150656 ...
      , 721527/3075328 , 1178085/24602624 , ...
      838645/6150656 , 60843/300032 , 345/6150656 , ...
      -4994121/24602624 , -100125/768832 , ...
      31911/768832 , 55219/768832 , 349515/24602624 , ...
      -63387/6150656 , -42305/12301312 , 5409/6150656 ...
      , 9015/24602624  ; ...
    -80385/5552128 , -240439/1388032 , 364155/5552128 ...
      , 105687/173504 , 1658587/2776064 , 75135/694016 ...
      , -2366403/5552128 , -217175/1388032 , ...
      853293/2776064 , 344085/1388032 , ...
      -268539/5552128 , -78363/694016 , -64665/2776064 ...
      , 5473/347008 , 29475/5552128 , -1803/1388032 , ...
      -3005/5552128];


  
 t2=[  5/2048 , 3/512 , -15/1024 , -25/512 , ...
      75/2048 , 75/256 , 231/512 , 75/256 , ...
      75/2048 , -25/512 , -15/1024 , 3/512 , 5/2048];
  
I2(1:3,1:17)=t1;      

I2(M_C-2:M_C,M_F-16:M_F)=fliplr(flipud(t1));

for i=4:M_C-3
    j=2*(i-4)+1;
    I2(i,j:j+12)=t2;
end

