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
#   Name       : TWaitDevice::TWaitDevice
#
#   Purpose....: Constructor for TWaitDevice		                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitDevice::TWaitDevice(TWait *Wait)
{
	Init(Wait);
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
TWaitDevice::TWaitDevice(const char *IniSection, TWait *Wait)
  : TDevice(IniSection)
{
	Init(Wait);
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
void TWaitDevice::Init(TWait *Wait)
{
    FWait = Wait;
    Wait->Add(this);
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
    FWait->Remove(this);
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
void TWait::Add(TWaitDevice *dev)
{
    dev->Add(FHandle, this);
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
    return (TWaitDevice *)RdosWaitForever(FHandle);
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
    return (TWaitDevice *)RdosWaitTimeout(FHandle, MilliSec);
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
