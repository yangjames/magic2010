function OutputMap(phase)
% fxn outputs a series of tif files and one text file with data from the
% current phase

global GMAP OOI ROBOT_PATH OOI_PATH NC_PATH MAGIC_CONSTANTS;

%color definitions:
CFILE = [0 44 207]/255;
CSCALE = [0 50 140]/255;
CDUNK = [226 226 227]/255;
CLUNK = [237 237 238]/255;
CSTART = [255 200 0]/255;
CWALL = [0 40 120]/255;
CFREEMIN = [128 128 128]/255;
CFREEMAX = [255 255 255]/255;
CFREEDEL = CFREEMAX - CFREEMIN;
COOI = [240 10 10]/255;
COOITEXT = [255 255 255]/255;
CRPATH = [120 0 140]/255;
COOIPATH = [240 10 10]/255;
CNCPATH = [0 255 0]/255;
MAPSIZE = 20; % size in meters of each small map

mapEoffset = MAGIC_CONSTANTS.mapEastOffset - MAGIC_CONSTANTS.mapEastMin;
mapNoffset = MAGIC_CONSTANTS.mapNorthOffset - MAGIC_CONSTANTS.mapNorthMin;

map = GMAP.data.cost;
map(map>100) = 100;
map(map < -100) = -100;
res = GMAP.resolution;
[xdim ydim] = size(map);

HEADERSPACE = 20; % number of pixels of space at the top of the map

% pre screen paths
RPATH.x=[];
RPATH.y=[];
NPATH.x=[];
NPATH.y=[];
OPATH.x=[];
OPATH.y=[];

for ID = 1:size(ROBOT_PATH,2)
    if ~isempty(ROBOT_PATH(ID))
        RPATH(ID).x = floor((ROBOT_PATH(ID).x + mapEoffset)/res);
        RPATH(ID).y = floor((ROBOT_PATH(ID).y + mapNoffset)/res);
    else
        RPATH(ID).x = [];
        RPATH(ID).y = [];
    end
end

for ID = 1:size(OOI_PATH,2)
    if ~isempty(OOI_PATH(ID))
        OPATH(ID).x = floor((OOI_PATH(ID).x + mapEoffset)/res);
        OPATH(ID).y = floor((OOI_PATH(ID).y + mapNoffset)/res);
    else
        OPATH(ID).x = [];
        OPATH(ID).y = [];
    end
end

for ID =1:size(NC_PATH, 2)
    if ~isempty(NC_PATH(ID))
        NPATH(ID).x = floor((NC_PATH(ID).x + mapEoffset)/res);
        NPATH(ID).y = floor((NC_PATH(ID).y + mapNoffset)/res);
    else
        NPATH(ID).x = [];
        NPATH(ID).y = [];
    end
end

% number of 20m sections in each direction
num_x = floor(xdim*res/MAPSIZE) + 1;
num_y = floor(ydim*res/MAPSIZE) + 1;
map(num_x*MAPSIZE/res, num_y*MAPSIZE/res) =0;


% add text for filename and scale marks
printname = ['MAGIC2010\_UPENN\_Mission' num2str(phase)];
filename = ['MAGIC2010_UPENN_Mission' num2str(phase)];
h=figure(99);
for x=1:num_x
    for y=1:num_y
        % calc endpoints of map
        minx = (x-1)*MAPSIZE/res +1;
        maxx = (x*MAPSIZE)/res;
        miny = (y-1)*MAPSIZE/res +1;
        maxy = (y*MAPSIZE)/res;
        
        % setup the plot map
        plot_map = map(minx:maxx, miny:maxy);
        plot_map = vertcat(zeros(HEADERSPACE,200), plot_map);
        
        %setup the output map
        out_map1(:,:) = repmat(CDUNK(1), MAPSIZE/res+HEADERSPACE, MAPSIZE/res);
        out_map2(:,:) = repmat(CDUNK(2), MAPSIZE/res+HEADERSPACE, MAPSIZE/res);
        out_map3(:,:) = repmat(CDUNK(3), MAPSIZE/res+HEADERSPACE, MAPSIZE/res);
        
        %make grid background
        for gx= 0:(MAPSIZE+HEADERSPACE*res -1)
            for gy=0:(MAPSIZE -1)
                if (mod(gx+gy, 2))
                    out_map1((gx/res)+1:((gx+1)/res), (gy/res)+1:((gy+1)/res)) = CLUNK(1);
                    out_map2((gx/res)+1:((gx+1)/res), (gy/res)+1:((gy+1)/res)) = CLUNK(2);
                    out_map3((gx/res)+1:((gx+1)/res), (gy/res)+1:((gy+1)/res)) = CLUNK(3);
                end
            end
        end
        
        % plot the known
        pmidx = plot_map < 0;
        out_map1(pmidx) = (-CFREEDEL(1).*plot_map(pmidx)/100)+CFREEMIN(1);
        out_map2(pmidx) = (-CFREEDEL(2).*plot_map(pmidx)/100)+CFREEMIN(2);
        out_map3(pmidx) = (-CFREEDEL(3).*plot_map(pmidx)/100)+CFREEMIN(3);
        
        %plot the presumed free by movement
        pmidx = plot_map > 2;
        out_map1(pmidx) = (CFREEDEL(1).*plot_map(pmidx)/100)+CFREEMIN(1);
        out_map2(pmidx) = (CFREEDEL(2).*plot_map(pmidx)/100)+CFREEMIN(2);
        out_map3(pmidx) = (CFREEDEL(3).*plot_map(pmidx)/100)+CFREEMIN(3);
        
        %plot the walls
        pmidx = plot_map >=90;
        out_map1(pmidx) = CWALL(1);
        out_map2(pmidx) = CWALL(2);
        out_map3(pmidx) = CWALL(3);
        
        out_map = cat(3, out_map1, out_map2, out_map3);
        
        clf(h); hold off; image(out_map); hold on; axis equal; axis tight;
        
        %add the filename
        text(10, 5, [printname '\_' num2str(x) '\_' num2str(y)], 'Color', CFILE, 'FontSize', 10);
        
        % scale
        plot([10 10], [10.5 20.5], 'Color', CSCALE);
        plot([9 11], [10.5 10.5], 'Color', CSCALE);
        plot([9 11], [20.5 20.5], 'Color', CSCALE);
        text(12, 15, '1m', 'Color', CSCALE, 'FontSize', 8);
        
        % orientation
        plot([35 35 30], [13 18 18], 'Color', CSCALE);
        text(36, 13, 'x', 'Color', CSCALE, 'FontSize', 6);
        text(30, 16, 'y', 'Color', CSCALE, 'FontSize', 6);
        
        % robot start
        for ID = 1:size(RPATH,2)
            if((RPATH(ID).x(1)>=minx) & (RPATH(ID).x(1) < maxx) & (RPATH(ID).y(1) >=miny) & (RPATH(ID).y(1) < maxy))
                patch(RPATH(ID).y(1)+[-1 0 1]-miny, RPATH(ID).x(1)+[1 -2 1]-minx+HEADERSPACE, CSTART);
            end
        end
        
        % plot the robot, OOI and NC paths
        for ID =1:size(RPATH)
            if ~isempty(RPATH(ID))
                robot_temp = ((RPATH(ID).x>=minx) & (RPATH(ID).x < maxx) & (RPATH(ID).y >=miny) & (RPATH(ID).y < maxy));
                if ~isempty(robot_temp)
                    plot(RPATH(ID).y(robot_temp)-miny, RPATH(ID).x(robot_temp)- minx+HEADERSPACE, 'Color', CRPATH, 'LineWidth', .02);
                end
            end
        end
        
        for ID = 1:size(OPATH)
            if ~isempty(OPATH(ID))
                ooi_temp = ((OPATH(ID).x>=minx) & (OPATH(ID).x < maxx) & (OPATH(ID).y >=miny) & (OPATH(ID).y < maxy));
                if ~isempty(ooi_temp)
                    plot(OPATH(ID).y(ooi_temp)-miny, OPATH(ID).x(ooi_temp)- minx +HEADERSPACE, 'Color', COOIPATH, 'LineWidth', .02);
                end
            end
        end
        
        for ID =1:size(NPATH,2)
            if ~isempty(NPATH(ID))
                nc_temp = ((NPATH(ID).x>=minx) & (NPATH(ID).x < maxx) & (NPATH(ID).y >=miny) & (NPATH(ID).y < maxy));
                if ~isempty(nc_temp)
                    plot(NPATH(ID).y(nc_temp)-miny, NPATH(ID).x(nc_temp) - minx +HEADERSPACE, 'Color', CNCPATH, 'LineWidth', .02);
                end
            end
        end
        
        % OOI info
        % need to add this
        
        
        
        set(gca, 'Position', [.01 .01 .98 .98], 'Visible', 'off', 'ActivePositionProperty', 'Position');
        orient tall
        drawnow;
        %output the file
        print(h, '-dtiff',  [filename '_' num2str(x) '_' num2str(y) '.tif']);
        
    end
end
end
