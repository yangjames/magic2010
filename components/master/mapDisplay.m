function mapDisplay(event, varargin)

global GCS
global RPOSE RMAP RPATH EXPLORE_PATH
global GPOSE GMAP GPATH
global RDISPLAY GDISPLAY
global PLANDISPLAY PLANMAP PLAN_DEBUG

axlim = 10;

ret = [];
switch event
  case 'entry'
    RDISPLAY.iframe = 1;

    % Setup individual robot windows
    for id = GCS.ids,
      figure(id+1);
      clf;
      set(gcf,'NumberTitle', 'off', 'Name',sprintf('Map: Robot %d',id));
      
      % Individual map
      x1 = x(RMAP{id});
      y1 = y(RMAP{id});
      RDISPLAY.hMap{id} = imagesc(x1, y1, ones(length(y1),length(x1)), [-100 100]);

      % Robot pose
      RDISPLAY.hRobot{id} = plotRobot(0, 0, 0, id);

      % Robot path
      hold on;
      RDISPLAY.path{id} = plot(0, 0, '-r');
      RDISPLAY.explore{id} = plot(0, 0, '-y');
      hold off;

      axis xy equal;
      axis([-axlim axlim -axlim axlim]);
      RDISPLAY.hAxes{id} = gca;
      set(gca,'Position', [.2 .1 .8 .8], 'XLimMode', 'manual', 'YLimMode', 'manual');
      colormap(jet);

      hfig = gcf;
      RDISPLAY.hFigure{id} = hfig;
      Std.Interruptible = 'off';
      Std.BusyAction = 'queue';
      RDISPLAY.stopControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Stop', ...
       'Callback', ['sendStateEvent(',num2str(id),',''stop'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .82 .15 .07]);
      RDISPLAY.backupControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Backup', ...
       'Callback', ['sendStateEvent(',num2str(id),',''backup'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .73 .15 .07]);
      RDISPLAY.spinLeftControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'SpinLeft', ...
       'Callback', ['sendStateEvent(',num2str(id),',''spinLeft'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .64 .15 .07]);
      RDISPLAY.spinRightControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'SpinRight', ...
       'Callback', ['sendStateEvent(',num2str(id),',''spinRight'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .55 .15 .07]);
      RDISPLAY.pathControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Path', ...
       'Callback', ['ginputPath(',num2str(id),')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .46 .15 .07]);
      % Button to force follow mode without obstacle detection
      RDISPLAY.forceControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Force', ...
       'Callback', ['sendStateEvent(',num2str(id),',''follow'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .37 .15 .07]);

      RDISPLAY.goToPointControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Go To Point', ...
       'Callback', ['ginputPoint(',num2str(id),')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .28 .15 .07]);
      RDISPLAY.goToPointControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Track', ...
       'Callback', ['ginputTrack(',num2str(id),')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .19 .15 .07]);
      RDISPLAY.exploreControl{id} = uicontrol(Std, ...
                                         'Parent', hfig, ...
                                         'Style', 'pushbutton', ...
                                         'String', 'Explore', ...
       'Callback', ['sendStateEvent(',num2str(id),',''explore'')'], ...
                                         'Units', 'Normalized', ...
                                         'Position', [.025 .10 .15 .07]);


    end


    % Setup global display window
    GDISPLAY.hFigure = figure(10);
    clf;
    set(gcf,'NumberTitle', 'off', 'Name',sprintf('Global Map'));
      
    % Individual map
    x1 = x(GMAP);
    y1 = y(GMAP);
    GDISPLAY.hMap = imagesc(x1, y1, ones(length(y1),length(x1)), [-100 100]);

    % Robot poses
    for id = GCS.ids,
      GDISPLAY.hRobot{id} = plotRobot(0, 0, 0, id);
    end

    axis xy equal;
    axis([-40 40 -40 40]);
    GDISPLAY.hAxes = gca;
    set(gca,'Position', [.1 .1 .8 .8], 'XLimMode', 'manual', 'YLimMode', 'manual');
    colormap(jet);
    drawnow

    if PLAN_DEBUG
      PLANDISPLAY.fig = figure(11);
      clf;
      set(gcf,'NumberTitle', 'off', 'Name',sprintf('Plan Map'));
      PLANDISPLAY.map = imagesc(PLANMAP.map);
      axis xy equal;
      GDISPLAY.hAxes = gca;
      set(gca,'Position', [.1 .1 .8 .8], 'XLimMode', 'manual', 'YLimMode', 'manual');
      colormap(jet);
      drawnow
    end

  case 'update'
    RDISPLAY.iframe = RDISPLAY.iframe + 1;

    for id = GCS.ids,
      map1 = RMAP{id};
      cost = getdata(map1, 'cost');
      set(RDISPLAY.hMap{id}, 'CData', cost');

      if ~isempty(RPOSE{id}),
        xp = RPOSE{id}.x;
        yp = RPOSE{id}.y;
        ap = RPOSE{id}.yaw;
        plotRobot(xp, yp, ap, id, RDISPLAY.hRobot{id});
        shiftAxes(RDISPLAY.hAxes{id}, xp, yp);
      end

      if ~isempty(RPATH{id})
        hold on;
        set(RDISPLAY.path{id},'x',RPATH{id}.x,'y',RPATH{id}.y);
        hold off;
      end

      if ~isempty(EXPLORE_PATH{id})
        hold on;
        set(RDISPLAY.explore{id},'x',EXPLORE_PATH{id}.x,'y',EXPLORE_PATH{id}.y);
        hold off;
      end
        
      if ~isempty(GPOSE{id}),
        plotRobot(GPOSE{id}.x, GPOSE{id}.y, GPOSE{id}.yaw, id, GDISPLAY.hRobot{id});
      end

    end

    cost = getdata(GMAP, 'cost');
    set(GDISPLAY.hMap, 'CData', cost');

    if PLAN_DEBUG
      %set(PLANDISPLAY.map, 'CData', PLANMAP.map);
      if(PLANMAP.new == 1)
        figure(11);
        PLANDISPLAY.map = imagesc(PLANMAP.map);
        axis xy;
        PLANMAP.new = 0;
      end
    end
    

    drawnow;


  case 'exit'
end

