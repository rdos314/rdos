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
# sigdev.cpp
# Signal device class
#
########################################################################*/

#include <string.h>
#include "device.h"
#include "sigdev.h"

#include <rdos.h>

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TSignalDevice::TSignalDevice
#
#   Purpose....: Constructor for TSignalDevice		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSignalDevice::TSignalDevice()
{
	Init();
}

/*##########################################################################
#
#   Name       : TSignalDevice::TSignalDevice
#
#   Purpose....: Constructor for TSignalDevice
#
#   In params..: IniSection to read parameters from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSignalDevice::TSignalDevice(const char *IniSection)
  : TWaitDevice(IniSection)
{
    Init();
}

/*##########################################################################
#
#   Name       : TSignalDevice::~TSignalDevice
#
#   Purpose....: Destructor for TSignalDevice		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSignalDevice::~TSignalDevice()
{
    RdosFreeSignal(FHandle);
}

/*##########################################################################
#
#   Name       : TSignalDevice::Init
#
#   Purpose....: Init method for class
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSignalDevice::Init()
{
	FHandle = RdosCreateSignal();
}

/*##########################################################################
#
#   Name       : TSignalDevice::DeviceName
#
#   Purpose....: Device name		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSignalDevice::DeviceName(char *Name, int MaxLen) const
{
	strncpy(Name, "SIGNAL", MaxLen);
}

/*##########################################################################
#
#   Name       : TSignalDevice::Add
#
#   Purpose....: Add object to wait
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSignalDevice::Add(TWait *Wait)
{
    if (FHandle)
    	RdosAddWaitForSignal(Wait->GetHandle(), FHandle, this);
}

/*##########################################################################
#
#   Name       : TSignalDevice::Clear
#
#   Purpose....: Clear
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSignalDevice::Clear()
{
	RdosResetSignal(FHandle);
}

/*##########################################################################
#
#   Name       : TSignalDevice::IsSignalled
#
#   Purpose....: Check if signalled
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSignalDevice::IsSignalled()
{
	return RdosIsSignalled(FHandle);
}

/*##########################################################################
#
#   Name       : TSignalDevice::Signal
#
#   Purpose....: Signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSignalDevice::Signal()
{
	RdosSetSignal(FHandle);
}

/*##########################################################################
#
#   Name       : TSignalDevice::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSignalDevice::SignalNewData()
{
}
