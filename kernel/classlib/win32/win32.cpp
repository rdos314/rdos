/*####################################  KERNEL.CPP                      #############################################
##    Description: Kernel function encapsulatiuon
##
##    Created....: 97-07-18 LE
####################################################################################################################*/

#include <windows.h>

/*##################  WaitMilli        ##########################
*   Purpose....: Waits for specified number of milliseconds
*   In params..: int MilliSec		Number of milliseconds to delay                              #
*   Created....: 97-07-18 LE
*   Last update: *
*###############################################################*/
void WaitMilli(long MilliSec)
{
	HANDLE thread_id;

	thread_id = GetCurrentThread();
    WaitForSingleObject(thread_id, MilliSec);
}

/*##################  ReadTimerTicks        ##########################
*   Purpose....: Reads number of system timer ticks
*   In params..: int MilliSec		Number of milliseconds to delay                              #
*   Created....: 97-07-18 LE
*   Last update: *
*###############################################################*/
unsigned long ReadTimerTicks(void)
{
	return 1079L * GetTickCount();
}

/*##################  CheckTimerRunning        ##########################
*   Purpose....: Check if timer is running                              #
*   Created....: 97-07-18 LE
*   Last update: *
*###############################################################*/
int CheckTimerRunning(unsigned long ExpireTime)
{
	unsigned long diff = ExpireTime - 1079L * GetTickCount();
    return (diff > 0x80000000);
}
