function ret = sScan(event, varargin)

global POSE GOAL QUEUELASER LFLAG
persistent DATA;
ret = [];
switch event
 case 'entry'
    disp('sScan');
    DATA.t0 = gettime;
    QUEUELASER = false;
    %GOAL_PREV = [];
    %tx = gettime;
 %{
 plannerState.shouldRun = 0;
 ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                 MagicGP_SET_STATESerializer('serialize', plannerState));
 %}

 case 'exit'
    
 case 'update'
    if ~isempty(GOAL)
        %dx = GOAL(1) - POSE.x ;
        %dy = GOAL(2) - POSE.y;
%         goal_ang = atan2(dy,dx); % let us make this to be from 0 - 2*pi
%         if(goal_ang < 0)
%              goal_ang = goal_ang + 2*pi;
%         end
        yw = POSE.yaw;
        if(yw < 0)
            yw = yw+2*pi;
        end
        gl_yw = GOAL(3);
        if(gl_yw < 0)
            gl_yw = gl_yw + 2*pi;
        end
        % Wait till the robot reaches that angle
        if(yaw-gl_yw>0.1) % Make the robot turn to that particular angle
            SetVelocity(0, sign(gl_yw-yw)*1.0);
            %ret = [];
            return;
        else
            SetVelocity(0,0);
            QUEUELASER = true; %%FIXME: How to make sure that this does not get set again for the same goal?
            %ret = [];
        end
    end
    
    % Once scan is done, this flag will be set to true
    if(LFLAG)
        ProcessLidarScans; % Create a costmap from the LIDAR scans
        LFLAG = false;
    %if(gettime - tx > 2)
        %disp('Exiting...');
        % Now scan the environment using the tilt lidar and make a costmap
        
        ret = 'plan';
    end

end
