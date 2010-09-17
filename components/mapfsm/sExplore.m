function ret = sExplore(event, varargin);

global MPOSE PATH_DATA
persistent DATA

ret = [];
switch event
 case 'entry'
  disp('sExplore');
  DATA.waitForGoal = 3;

  %{
  PATH_DATA.type = 2;
  plannerState.shouldRun = 2;
  ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                  MagicGP_SET_STATESerializer('serialize', plannerState));
  %}

 case 'exit'
   %{
   plannerState.shouldRun = 0;
   ipcAPIPublishVC(GetMsgName('Planner_State'), ...
                   MagicGP_SET_STATESerializer('serialize', plannerState));
   %}
  
 case 'update'

   if PATH_DATA.newExplorePath
      PATH_DATA.newExplorePath = false;
      PATH_DATA.goToPointGoal = PATH_DATA.explorePath;
      sGoToPoint('entry');
      DATA.waitForGoal = 0;
   end
   
   switch DATA.waitForGoal
     case 0
       ret = sGoToPoint('update');
       if strcmp(ret,'done')
         DATA.waitForGoal = 1;
       end
     case 1
       sSpinLeft('entry');
       DATA.waitForGoal = 2;
     case 2
       ret = sSpinLeft('update');
       if strcmp(ret,'done') || strcmp(ret,'timeout')
         DATA.waitForGoal = 3;
       end
     case 3
       sSpinLeft('exit');
   end

   ret = [];

end
