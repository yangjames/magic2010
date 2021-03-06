#include "common_headers.h"

using namespace std;


#include "../../common/dataTypes/MagicPlanDataTypes.h"
#include "../../ipc/ipc.h"


#define MODULE_NAME "Exploration"


GP_PLANNER_PARAMETER planner;
GP_POSITION_UPDATE position;
GP_FULL_UPDATE maps;
GPLAN gplan;

static void DATAhandler(MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	GP_DATA_PTR data;
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **) &data);
  IPC_printData(IPC_msgFormatter(GP_DATA_MSG), stdout, data);

	if ((planner.NR != data->NR) || (planner.GP_PLAN_TIME != data->GP_PLAN_TIME) || (planner.DIST_GAIN != data->DIST_GAIN) || (planner.MIN_RANGE != data->MIN_RANGE)
			|| (planner.MAX_RANGE != data->MAX_RANGE) || (planner.DIST_PENALTY != data->DIST_PENALTY) || (planner.REGION_PENALTY != data->REGION_PENALTY)
			|| (planner.map_cell_size != data->map_cell_size) || (planner.map_size_x != data->map_size_x) || (planner.map_size_y != data->map_size_y))
	{
		planner.NR = data->NR;             // number of robots
		planner.GP_PLAN_TIME = data->GP_PLAN_TIME; // seconds to allow for planning
		planner.DIST_GAIN = data->DIST_GAIN;
		planner.MIN_RANGE = data->MIN_RANGE;	// desired min and max ranges to nearest other robot in the same region
		planner.MAX_RANGE = data->MAX_RANGE; 
		planner.DIST_PENALTY = data->DIST_PENALTY;		// penalty per cell for being outside desird range (delta cells * DIST_PENALTY)
		planner.REGION_PENALTY = data->REGION_PENALTY;		// penalty for being in the same region as another robot (does not apply for outside)
		// map sizes
		planner.map_cell_size = data->map_cell_size;	// size of map cell in meters
		planner.map_size_x = data->map_size_x;		// size of sent map in x dimension in cells 
		planner.map_size_y = data->map_size_y;		// size of sent map in y dimension in cells 
		gplan.gplan_init(&planner);
	}

//	maps.UTM_x = data->UTM_x;		// UTM x offset in meters
//	maps.UTM_y = data->UTM_y;		// UTM y offset in meters


	// robot poses and availability
	delete [] position.avail;
	delete [] position.x;
	delete [] position.y;
	delete [] position.theta;

	position.avail = new int[planner.NR];
	position.x = new double[planner.NR];
	position.y = new double[planner.NR];
	position.theta = new double[planner.NR];

	//memcpy((void *)position.avail, (void *)data->avail, planner.NR*sizeof(int));
	memcpy((void *)position.x, (void *)data->x, planner.NR*sizeof(double));
	memcpy((void *)position.y, (void *)data->y, planner.NR*sizeof(double));
	memcpy((void *)position.theta, (void *)data->theta, planner.NR*sizeof(double));

	// un-UTM the positions
	for (int ridx = 0; ridx < planner.NR; ridx++) {
		position.x[ridx] -= data->UTM_x;
		position.y[ridx] -= data->UTM_y;
		position.avail[ridx] = (int)data->avail[ridx];
	}


	// maps
	delete [] maps.coverage_map;
	delete [] maps.cost_map;
	delete [] maps.elev_map;
	delete [] maps.region_map;
    delete [] maps.bias_table;

    maps.num_regions = data->num_regions;
    maps.num_states = data->num_states;
    if(maps.num_states != planner.NR +2) { printf("FAIL: bias table is wrong dimensions\n"); }

	maps.coverage_map = new unsigned char[planner.map_size_x * planner.map_size_y];
	maps.cost_map = new unsigned char[planner.map_size_x * planner.map_size_y];
	maps.elev_map = new int16_t[planner.map_size_x * planner.map_size_y];
	maps.region_map = new unsigned char[planner.map_size_x * planner.map_size_y];
    maps.bias_table = new double[maps.num_regions * maps.num_states];

	memcpy((void *)maps.region_map, (void *)data->region_map, planner.map_size_x*planner.map_size_y*sizeof(unsigned char));
    memcpy((void *)maps.bias_table, (void *)data->bias_table, maps.num_regions*maps.num_states*sizeof(double));
    
	for (int j = 0; j < planner.map_size_y; j++) {
		for (int i = 0; i < planner.map_size_x; i++) {
			if(data->map[i+planner.map_size_x*j] > 75)  {
				maps.coverage_map[i+planner.map_size_x*j] = KNOWN; 
				maps.cost_map[i+planner.map_size_x*j] = OBSTACLE;
			}
else if(data->map[i+planner.map_size_x*j] > 2.0)  {
				maps.coverage_map[i+planner.map_size_x*j] = KNOWN; 
				maps.cost_map[i+planner.map_size_x*j] = 0;
			}

			else if(data->map[i+planner.map_size_x*j] < -1)  {
				maps.coverage_map[i+planner.map_size_x*j] = KNOWN; 
				maps.cost_map[i+planner.map_size_x*j] = 0;
			}
			else {
				maps.coverage_map[i+planner.map_size_x*j] = UNKNOWN; 
				maps.cost_map[i+planner.map_size_x*j] = 0;
			}

			maps.elev_map[i+planner.map_size_x*j] = (int16_t)(maps.cost_map[i+planner.map_size_x*j]*100);
		}
	}

	vector< vector<Traj_pt_s> > traj = gplan.gplan_plan(&position, &maps);

	// handle return stuff
	GP_TRAJ GPtraj;
	GPtraj.NR = planner.NR;
	GPtraj.total_size = 0;
	for (int ridx = 0; ridx < traj.size(); ridx++) {
		GPtraj.total_size += traj[ridx].size();
	}

	GPtraj.traj_size = new uint16_t[GPtraj.NR];
	GPtraj.POSEX = new double[GPtraj.total_size];
	GPtraj.POSEY = new double[GPtraj.total_size];
	GPtraj.POSETHETA = new double[GPtraj.total_size];

	uint16_t ptr=0;
	for (int ridx = 0; ridx < traj.size(); ridx++) {
		GPtraj.traj_size[ridx] = ptr;
		for (int tidx = 0; tidx < traj[ridx].size(); tidx++) {
			GPtraj.POSEX[ptr] = traj[ridx][tidx].xx + data->UTM_x;
			GPtraj.POSEY[ptr] = traj[ridx][tidx].yy + data->UTM_y;
			GPtraj.POSETHETA[ptr] = traj[ridx][tidx].theta;
			ptr++;
		}

	}

	//publish trajectory
	IPC_publishData(GP_TRAJ_MSG, &GPtraj); 

	//free memory used by message
	IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *) data);
	IPC_freeByteArray(callData);
}



int main () {
	planner.WRITE_FILES = 0; // flag to write files out
	planner.DISPLAY_OUTPUT =1; // flag to display any output
	planner.SENSORWIDTH = M_PI;
	planner.THETA_BIAS = 1; // 0 to 1 bias on rough direction to goal location default is 1
	planner.sensor_radius = 7.0;		// sensing radius of robot in m
	planner.sensor_height = 120;		// sensing height of robot in cm
	planner.perimeter_radius = .25;	// radius of bounding circle



	position.avail = new int[1];
	position.x = new double[1];
	position.y = new double[1];
	position.theta = new double[1];

	maps.coverage_map = new unsigned char[1];
	maps.cost_map = new unsigned char[1];
	maps.elev_map = new int16_t[1];
	maps.region_map = new unsigned char[1];
    maps.bias_table = new double[1];


	//IPC stuff
	IPC_connectModule(MODULE_NAME, "localhost");
	IPC_defineMsg(GP_TRAJ_MSG, IPC_VARIABLE_LENGTH, GP_TRAJ_FORM);
	IPC_setMsgQueueLength(GP_TRAJ_MSG, 10);

	/* Subscribe to the messages that this module listens to. */
	printf("\nIPC_subscribe(%s, GP_DATA_Handler, %s)\n", GP_DATA_MSG, MODULE_NAME);
	IPC_subscribe(GP_DATA_MSG, DATAhandler, (void *)MODULE_NAME);
	IPC_setMsgQueueLength(GP_DATA_MSG, 1);

	IPC_dispatch();

	//clean up on exit
	IPC_disconnect();
	return(0);
}

