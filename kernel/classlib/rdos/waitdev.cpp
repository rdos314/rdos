/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# waitdev.cpp
# Waitable device class
#
########################################################################*/

#include "waitdev.h"

#include <rdos.h>

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : ThreadStartup
#
#   Purpose....: Startup procedure for thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void ThreadStartup(void *ptr)
{
	((TWait *)ptr)->Execute();
}

/*##########################################################################
#
#   Name       : TWaitDevice::TWaitDevice
#
#   Purpose....: Constructor for TWaitDevice		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitDevice::TWaitDevice()
{
	Init();
}

/*##########################################################################
#
#   Name       : TWaitDevice::TWaitDevice
#
#   Purpose....: Constructor for TWaitDevice		                          
#
#   In params..: IniSection to read parameters from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitDevice::TWaitDevice(const char *IniSection)
  : TDevice(IniSection)
{
	Init();
}

/*##########################################################################
#
#   Name       : TWaitDevice::Init
#
#   Purpose....: Init method for class
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWaitDevice::Init()
{
    FWait = 0;
}

/*##########################################################################
#
#   Name       : TWaitDevice::RegisterWait
#
#   Purpose....: Register with wait
#   In params..: *
#   Out params.: *
#   Returns....: handle to wait
#
##########################################################################*/
int TWaitDevice::RegisterWait(TWait *Wait)
{	
	FWait = Wait;
    return FWait->GetHandle();
}

/*##########################################################################
#
#   Name       : TWaitDevice::~TWaitDevice
#
#   Purpose....: Destructor for TDevice		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitDevice::~TWaitDevice()
{
	if (FWait)
	    FWait->Remove(this);
}

/*##########################################################################
#
#   Name       : TWaitDevice::GetWait
#
#   Purpose....: Get wait
#   In params..: *
#   Out params.: *
#   Returns....: handle to wait
#
##########################################################################*/
TWait *TWaitDevice::GetWait()
{	
	return FWait;
}

/*##########################################################################
#
#   Name       : TWait::TWait
#
#   Purpose....: Constructor for TWait		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWait::TWait()
{
    FHandle = RdosCreateWait();
	FInstalled = TRUE;
	FThreadRunning = FALSE;
}

/*##########################################################################
#
#   Name       : TWait::~TWait
#
#   Purpose....: Destructor for TWait		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWait::~TWait()
{
	FInstalled = FALSE;
	if (FThreadRunning)
		RdosStopWait(FHandle);

	while (FThreadRunning)
		RdosWaitMilli(25);

    RdosCloseWait(FHandle);
}

/*##########################################################################
#
#   Name       : TWait::Add
#
#   Purpose....: Add a new waitable object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWait::GetHandle()
{
    return FHandle;
}

/*##########################################################################
#
#   Name       : TWait::Remove
#
#   Purpose....: Remove a waitable object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWait::Remove(TWaitDevice *dev)
{
	RdosRemoveWait(FHandle, dev);
}

/*##########################################################################
#
#   Name       : TWait::StartThreadHandler
#
#   Purpose....: Start a thread that handles wait object
#
#   In params..: StackSize		Size of stack
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWait::StartThreadHandler(const char *ThreadName, int StackSize)
{
	RdosCreateThread(ThreadStartup, ThreadName, this, StackSize);
}

/*##########################################################################
#
#   Name       : TWait::Check
#
#   Purpose....: Check if signalled, and return signalled object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitDevice *TWait::Check()
{
    return (TWaitDevice *)RdosCheckWait(FHandle);
}

/*##########################################################################
#
#   Name       : TWait::WaitForever
#
#   Purpose....: Wait forever for object(s), and return signalled object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitDevice *TWait::WaitForever()
{
	TWaitDevice *Wait;

    Wait = (TWaitDevice *)RdosWaitForever(FHandle);
	if (Wait)
		Wait->SignalNewData();

	return Wait;
}

/*##########################################################################
#
#   Name       : TWait::WaitTimeout
#
#   Purpose....: Wait with timeout for object(s), and return signalled object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitDevice *TWait::WaitTimeout(int MilliSec)
{
	TWaitDevice *Wait;

    Wait = (TWaitDevice *)RdosWaitTimeout(FHandle, MilliSec);
	if (Wait)
		Wait->SignalNewData();

	return Wait;
}

/*##########################################################################
#
#   Name       : TWait::Abort
#
#   Purpose....: Abort wait from another thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWait::Abort()
{
    RdosStopWait(FHandle);
}

/*##########################################################################
#
#   Name       : TWait::Execute
#
#   Purpose....: Thread based handler
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWait::Execute()
{
	TWaitDevice *Wait;

	while (FInstalled)
	{
	    Wait = (TWaitDevice *)RdosWaitForever(FHandle);
		if (Wait)
			Wait->SignalNewData();
	}
}
