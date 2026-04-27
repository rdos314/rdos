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
 : TWaitDevice("Syslog")
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
