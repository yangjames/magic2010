function keypress(source,eventdata)

global GDISPLAY

switch(eventdata.Character)
case '1'
  set(GDISPLAY.grp,'SelectedObject',GDISPLAY.robotRadioControl{1});
  GDISPLAY.selectedRobot = 1;
case '2'
  set(GDISPLAY.grp,'SelectedObject',GDISPLAY.robotRadioControl{2});
  GDISPLAY.selectedRobot = 2;
case '3'
  set(GDISPLAY.grp,'SelectedObject',GDISPLAY.robotRadioControl{3});
  GDISPLAY.selectedRobot = 3;
case '4'
  set(GDISPLAY.grp,'SelectedObject',GDISPLAY.robotRadioControl{4});
  GDISPLAY.selectedRobot = 4;
case '5'
  set(GDISPLAY.grp,'SelectedObject',GDISPLAY.robotRadioControl{5});
  GDISPLAY.selectedRobot = 5;
case '6'
  set(GDISPLAY.grp,'SelectedObject',GDISPLAY.robotRadioControl{6});
  GDISPLAY.selectedRobot = 6;
case '7'
  set(GDISPLAY.grp,'SelectedObject',GDISPLAY.robotRadioControl{7});
  GDISPLAY.selectedRobot = 7;
case '8'
  set(GDISPLAY.grp,'SelectedObject',GDISPLAY.robotRadioControl{8});
  GDISPLAY.selectedRobot = 8;
end
GDISPLAY.selectedRobot