#ifndef MAGIC_MICRO_COM_H
#define MAGIC_MICRO_COM_H

#include <stdio.h>


#define MMC_READY_MSG "\r\nMAGIC Controller Ready\r\n"
#define MMC_GPS_LINE_SIZE_MAX 128

enum { MMC_MAIN_CONTROLLER_DEVICE_ID,
       MMC_GPS_DEVICE_ID,
       MMC_IMU_DEVICE_ID,
       MMC_MOTOR_CONTROLLER_DEVICE_ID,
       MMC_DYNAMIXEL0_DEVICE_ID,
       MMC_DYNAMIXEL1_DEVICE_ID,
       MMC_GATEWAY_DEVICE_ID,
       MMC_RC_DEVICE_ID,
       MMC_ESTOP_DEVICE_ID,
       MMC_MASTER_DEVICE_ID
     };


enum { MMC_MASTER_ROBOT_SELECT };

//main conroller packet
enum { MMC_MC_RESET,
       MMC_MC_MODE_SWITCH,
       MMC_MC_EEPROM_READ,
       MMC_MC_EEPROM_WRITE,
       MMC_MC_SERVO1_MODE
     };


enum { MMC_MC_MODE_IDLE,
       MMC_MC_MODE_RUN,
       MMC_MC_MODE_CONFIG
     };

//gps packet types
enum { MMC_GPS_ASCII };

//imu packet types
enum { MMC_IMU_RAW, 
       MMC_IMU_FILTERED, 
       MMC_IMU_ROT, 
       MMC_MAG_RAW,
       MMC_IMU_RESET
     };

//motor controller packet types
enum { MMC_MOTOR_CONTROLLER_ENCODERS_REQUEST,
       MMC_MOTOR_CONTROLLER_ENCODERS_RESPONSE,
       MMC_MOTOR_CONTROLLER_VELOCITY_SETTING,
       MMC_MOTOR_CONTROLLER_VELOCITY_CONFIRMATION
     };
     
//rc packet types
enum { MMC_RC_RAW,
       MMC_RC_DECODED
     };

//estop packet types
enum { MMC_ESTOP_STATE
     };

enum { MMC_ESTOP_STATE_RUN,
       MMC_ESTOP_STATE_PAUSE,
       MMC_ESTOP_STATE_DISABLE
     };


#endif //MAGIC_MIRCO_COM_H

