/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# win32.cpp
# Encapsulation of low level time(r) functions
#
########################################################################*/

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
