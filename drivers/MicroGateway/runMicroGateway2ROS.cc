#include "ErrorMessage.hh"
#include "MicroGatewayROS.hh"
#include "Timer.hh"
#include "DynamixelPacket.h"
#include "MagicMicroCom.h"


using namespace std;
using namespace Upenn;


int main(int argc, char * argv[])
{
  char * sDev = (char*)"/dev/microGateway";
  char * ipcHost = NULL;

  //get input arguments
  if (argc > 1)
  {
    sDev = argv[1];
  }
  
  
  if (argc > 2)
    ipcHost = argv[2];

  //call ros::init() before creating the MicroGateway object
  ros::init(argc, argv, "MicroGateway"); 

  //connect to the serial bus
  MicroGateway * mg = new MicroGateway();
  if (mg->ConnectSerial(sDev,1000000))
  {
    PRINT_ERROR("could not connect to the serial bus\n");
    return -1;
  }

  if (mg->ConnectIPC())
  {
    PRINT_ERROR("could not connect to ipc\n");
    return -1;
  }

  if (mg->ConnectROS()) { 
	PRINT_ERROR("could not connect to ROS\n"); 
	return -1; 
  }
  
  PRINT_INFO("everything connected, starting main loop\n"); 

  while(1)
  {
    mg->Main();
  }
  
  return 0;
}

