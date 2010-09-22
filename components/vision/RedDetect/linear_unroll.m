function urimg = linear_unroll(img,cx,cy,rmax)
%uh = 125
%uw = 1200
%rmin = 230
%rmax = 400
width = size(img,2); 
height = size(img,1); ; 
uh = 200
uw = 1000
rmin = rmax*.40; 
rmax = rmax*.90;;
rrange = rmax - rmin; 
%cx = 400
%cy = 300 
[I,J] = meshgrid(1:uw,1:uh);
PI = I * (2*pi/uw); 
Uy = sin(PI); 
Ux = cos(PI);
Jscaled = J * (rrange/uh) + rmin;  
RX = Ux .* Jscaled; 
RY = Uy .* Jscaled;  
RX = RX + cx;
RY = RY + cy;
BAD = (RX < 1) + (RX > width) + (RY < 1) + (RY > height);  
BAD = BAD > 0; 
RX(RX < 1) = 1;   
RY(RY < 1) = 1;   
RX(RX > width) = 1;    
RY(RY > height) = 1;
RY = round(RY); 
RX = round(RX); 
%RX(RX == 0) = 1;  
%RY(RY == 0) = 1;
R = img(:,:,1);   
G = img(:,:,2);   
B = img(:,:,3);   
IND = sub2ind([height,width],RY,RX);
urimg(BAD) = -1; 
urimg = R(IND) .* uint8(~BAD); 
urimg(:,:,2) = G(IND) .* uint8(~BAD); 
urimg(:,:,3) = B(IND) .* uint8(~BAD); 
urimg = imrotate(urimg,180); 