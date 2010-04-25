clear all;
addpath( [ getenv('VIS_DIR') '/ipc' ] )
addpath( [ getenv('VIS_DIR') '/Interfaces' ] )


ipcAPIConnect;
pointCloudTypeName = 'PointCloud3DColorDoubleRGBA';
pointCloudMsgName = ['pointCloud' VisMarshall('getMsgSuffix',pointCloudTypeName)];
pointCloudFormat  = VisMarshall('getMsgFormat',pointCloudTypeName);
ipcAPIDefine(pointCloudMsgName,pointCloudFormat);

lidarPointsTypeName = 'PointCloud3DColorDoubleRGBA';
lidarPointsMsgName = ['lidar1Points' VisMarshall('getMsgSuffix',lidarPointsTypeName)];
lidarPointsFormat  = VisMarshall('getMsgFormat',lidarPointsTypeName);
ipcAPIDefine(lidarPointsMsgName,lidarPointsFormat);


poseMsgName = ['robot' VisMarshall('getMsgSuffix','Pose3D')];
poseMsgFormat  = VisMarshall('getMsgFormat','Pose3D');
ipcAPIDefine(poseMsgName,poseMsgFormat);

surfMsgName = 'heightmap_surface2d';
surfMsgFormat = VisSurface2DSerializer('getFormat');
ipcAPIDefine(surfMsgName,surfMsgFormat);

surfUpdateMsgName = 'heightmap_surface2dUpdate';
surfUpdateMsgFormat = VisSurface2DUpdateSerializer('getFormat');
ipcAPIDefine(surfUpdateMsgName,surfUpdateMsgFormat);



%load ~/Desktop/MappingLogs/OutsideMoore308/Hokuyo0.mat
load ~/Desktop/fin/Hokuyo0_3.mat

nPointsUtm=1081;
resUtm = 0.25;
anglesUtm=((0:resUtm:(nPointsUtm-1)*resUtm)-135)'*pi/180;

rangesMat = Hokuyo0.ranges;
anglesMat = repmat(anglesUtm,[1,size(rangesMat,2)]);
cosines = cos(anglesMat);
sines   = sin(anglesMat);

ts = Hokuyo0.ts;

xs = rangesMat .* cosines;
ys = rangesMat .* sines;
zs = zeros(size(xs));
onez = ones(size(xs,1),1);

xss = zeros(size(xs));
yss = zeros(size(ys));
zss = zeros(size(zs));

len = size(xs,2);


res = 0.05;
invRes = 1/res;

xmin = -40;
ymin = -50;
xmax = 85;
ymax = 100;
zmin = 0;
zmax = 5;

sizex = (xmax - xmin) * invRes;
sizey = (ymax - ymin) * invRes;

ScanMatch2D('setBoundaries',xmin,ymin,xmax,ymax);
ScanMatch2D('setResolution',res);


mapp = [];
mapType = 'uint8';
map  = zeros(sizex,sizey,mapType);

yaw =(10.5-45)/180*pi; %1.5
x=0;
y=0;
z=0;



positions = zeros(3,len);

rotCntr = 1;





heightData.sizex=sizex;
heightData.sizey=sizey;
heightData.data = zeros(sizex,sizey,'single');

props.resx = res;
props.resy = res;
props.interpx = 0;
props.interpy = 0;
props.lineSepX = 20.0;
props.lineSepY = 20.0;

surface.heightData = heightData;
surface.props = props;

%content = VisSurface2DSerializer('serialize',surface);
%ipcAPIPublishVC(surfMsgName,content);

hHough = [];
hAccum = [];

hhPrev = [];



for i=1:len
  pose = [0 0 0];
  
  ranges = rangesMat(:,i);
  
  
  indGood = ranges >0.25;
  
  xsss=xs(indGood,i);
  ysss=ys(indGood,i);
  zsss=zs(indGood,i);
  onez=ones(size(xsss));
  
  
  
 
  
  xsh = xsss(1:5:end);
  ysh = ysss(1:5:end);
  
  %[h_trans angles rhos]
  
   a_center = 0; %pi/2;
  a_range  = pi/2;
  a_res = pi/200;
  r_center =0;
  r_range = 5;
  r_res   = 0.10;
  
  
  [h_trans] = HoughTransformAPI(xsh,ysh,a_center,a_range,a_res,r_center, r_range, r_res);
  
  h_trans(h_trans<10) = 0;
  hh = sum(h_trans,1);
  
  
  
  if isempty(hhPrev)
    hhPrev = hh;
  end
  
  cshift = -5:5;
  clen = length(cshift);
  cvals= zeros(clen,1);
  for s=1:clen;
    cvals(s) = sum(hh'.*(circshift(hhPrev',cshift(s))));
  end

  [cmax cimax] = max(cvals);
  hhPrev = hh;
  
  %toc
  
  
  if (isempty(mapp))
    T = rotz(yaw);
    X = [xsss'; ysss';zsss';onez'];
    Y=T*X;

    xss = Y(1,:)' +x;
    yss = Y(2,:)' +y;
    zss = Y(3,:)' +z;

    xis = ceil((xss - xmin) * invRes);
    yis = ceil((yss - ymin) * invRes);
    indGood = (xis > 1) & (yis > 1) & (xis < sizex) & (yis < sizey);
  
   inds = sub2ind(size(map),xis(indGood),yis(indGood));
    mapp=zeros(size(map),mapType);
    mapp(inds) = 100;
    continue;
  end
  
  
  
  %fprintf(1,'------------------------');
  
  nyaw= 31;
  nxs = 11;
  nys = 11;

  dyaw = 0.20/180.0*pi;
  dx   = 0.01;
  dy   = 0.01;
  
  aCand = (-15:15)*dyaw+yaw ; %+ (-cshift(cimax))*a_res;
  xCand = (-5:5)*dx+x;
  yCand = (-5:5)*dy+y;
  
  hits = ScanMatch2D('match',mapp,xsss,ysss,xCand,yCand,aCand);
  
  
  [hmax imax] = max(hits(:));
  [kmax mmax jmax] = ind2sub([nxs,nys,nyaw],imax);
  
  yaw = aCand(jmax);
  x   = xCand(kmax);
  y   = yCand(mmax);
  positions(:,i) = [x;y;yaw];
 
  T = (trans([x y 0])*rotz(yaw))';
  X = [xsss ysss zsss onez];
  Y=X*T;
  
  
  xss = Y(:,1);
  yss = Y(:,2);
 
  xis = ceil((xss - xmin) * invRes);
  yis = ceil((yss - ymin) * invRes);
  
  indGood = (xis > 1) & (yis > 1) & (xis < sizex) & (yis < sizey);
  inds = sub2ind(size(map),xis(indGood),yis(indGood));
  
  mapp(inds)= mapp(inds)+3;
  
  if (mod(i,25)==0)
    indd=mapp<50 & mapp > 0;
    mapp(indd) = mapp(indd)*0.95;
    mapp(mapp>100) = 100;
  end
  
  if (mod(i,25)==0)
    vpose = [x y 1 pose(1) -pose(2) yaw];
    content = VisMarshall('marshall','Pose3D',vpose);
    ipcAPIPublishVC(poseMsgName,content);
  end
  
  if (mod(i,100)==0)
    lxs = xss';
    lys = yss';
    lzs = zeros(size(lxs));
    lrs = zeros(size(lxs));
    lgs = ones(size(lxs));
    lbs = 0.5*ones(size(lxs));
    las = ones(size(lxs));
    data = [lxs; lys; lzs; lrs; lgs; lbs; las];

    content = VisMarshall('marshall', lidarPointsTypeName,data);
    ipcAPIPublishVC(lidarPointsMsgName,content);
  end
  
  %{
  if (mod(i,500)==0)
    inds = find((mapp(:) > 0));
    [subx suby] = ind2sub(size(map),inds);
    
    surfUpdate.heightData.size = length(inds);
    surfUpdate.xs.size = surfUpdate.heightData.size;
    surfUpdate.ys.size = surfUpdate.heightData.size;
    
    surfUpdate.heightData.data = single(mapp(inds))/100;
    surfUpdate.xs.data = uint32(subx);
    surfUpdate.ys.data = uint32(suby);
    
    content = VisSurface2DUpdateSerializer('serialize',surfUpdate);
    ipcAPIPublishVC(surfUpdateMsgName,content);
  end
  %}
  
  if (mod(i,100)==0)
    
    %set(hMap,'cdata',mapp');
    
    inds = find((mapp(:) > 50));
    [subx suby] = ind2sub(size(map),inds);
    
    %position
    vxs = subx'*res + xmin;
    vys = suby'*res + ymin;
    vzs = 0.01*ones(size(vxs));

    %color information
    vrs = double((mapp(inds)/100)');
    vgs = 1-vrs;
    vbs = 0.2*ones(size(vxs));
    vas = 0.5*ones(size(vxs));

    data = [vxs; vys; vzs; vrs; vgs; vbs; vas];

    content = VisMarshall('marshall', pointCloudTypeName,data);
    ipcAPIPublishVC(pointCloudMsgName,content);
    
    
    %{
    surface.heightData.data = single(mapp)/100;
    content = VisSurface2DSerializer('serialize',surface);
    ipcAPIPublishVC(surfMsgName,content);
    %}
  end
  
  %set(h,'xdata',xss,'ydata',yss);
  %drawnow;
end


