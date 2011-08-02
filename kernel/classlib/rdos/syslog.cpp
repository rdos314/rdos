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
# syslog.cpp
# Syslog device class
#
########################################################################*/

#include <string.h>
#include "syslog.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TSyslogDevice::TSyslogDevice
#
#   Purpose....: Constructor
#
#   In params..: *
#   Returns....: *
#
##########################################################################*/
TSyslogDevice::TSyslogDevice()
{
    FHandle = RdosOpenSyslog();
}

/*##########################################################################
#
#   Name       : TSyslogDevice::~TSyslogDevice
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSyslogDevice::~TSyslogDevice()
{
    RdosCloseSyslog(FHandle);
}

/*##########################################################################
#
#   Name       : TSyslogDevice::DeviceName
#
#   Purpose....: Returns device-name
#
#   In params..: MaxLen max size of name
#   Out params.: Name   device name
#   Returns....: *
#
##########################################################################*/
void TSyslogDevice::DeviceName(char *Name, int MaxLen) const
{
        strncpy(Name,"Syslog device",MaxLen);
}

/*##########################################################################
#
#   Name       : TSyslogDevice::Add
#
#   Purpose....: Add object to wait
#
#   In params..: wait
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSyslogDevice::Add(TWait *Wait)
{
    RdosAddWaitForSyslog(Wait->GetHandle(), FHandle, this);
}

/*##########################################################################
#
#   Name       : TSyslogDevice::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSyslogDevice::SignalNewData()
{
}

/*##########################################################################
#
#   Name       : TSyslogDevice::WaitForLog
#
#   Purpose....: Wait for log
#
#   In params..: *
#   Out params.: *
#   Returns....: character
#
##########################################################################*/
void TSyslogDevice::WaitForLog()
{
    if (!FWait)
        CreateWait();

    for (;;)
    {
        if (FWait->WaitForever() == this)
                        return;
        }
}

/*##########################################################################
#
#   Name       : TSyslogDevice::GetLog
#
#   Purpose....: Get log entry
#
#   In params..: *
#   Out params.: *
#   Returns....: character
#
##########################################################################*/
int TSyslogDevice::GetLog(int *facility, int *severity, TDateTime &time, TString &log)
{
    char *buf;
    unsigned long lsb, msb;

    buf = new char[512];

    *facility = RdosGetSyslog(FHandle, severity, &msb, &lsb, buf, 512);

    if (*facility)
    {
        log = TString(buf);
        time = TDateTime(msb, lsb);
        delete buf;
        return TRUE;
    }
    else
    {
        log = "";
        delete buf;
        return FALSE;
    }
}
