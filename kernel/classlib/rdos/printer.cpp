/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2011, Leif Ekblad
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
# printer.cpp
# Printer device class
#
########################################################################*/

#include <string.h>
#include "printer.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPrinterDevice::TPrinterDevice
#
#   Purpose....: Constructor
#
#   In params..: IniSection Parameter section
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPrinterDevice::TPrinterDevice(const char *IniSection)
	: TWaitDevice(IniSection)
{
    FHandle = 0;
    FPort = 0;
}

/*##########################################################################
#
#   Name       : TPrinterDevice::TPrinterDevice
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPrinterDevice::TPrinterDevice()
{
    FHandle = 0;
    FPort = 0;
}

/*##########################################################################
#
#   Name       : TPrinterDevice::TPrinterDevice
#
#   Purpose....: Constructor
#
#   In params..: IniSection Parameter section
#                Port       port number (ie first printer = 1)
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPrinterDevice::TPrinterDevice(const char *IniSection, int Port)
	: TWaitDevice(IniSection)
{
	Init(Port);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::TPrinterDevice
#
#   Purpose....: Constructor
#
#   In params..: Port       port number (ie first printer = 1)
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPrinterDevice::TPrinterDevice(int Port)
{
	Init(Port);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::~TPrinterDevice
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPrinterDevice::~TPrinterDevice()
{
    if (FHandle)
        RdosClosePrinter(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::Init
#
#   Purpose....: Init device
#
#   In params..: Port       port number (ie first printer = 1)
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPrinterDevice::Init(int Port)
{
    FPort = Port - 1;
    FHandle = RdosOpenPrinter(FPort);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::DeviceName
#
#   Purpose....: Returns device-name
#
#   In params..: MaxLen max size of name
#   Out params.: Name   device name
#   Returns....: *
#
##########################################################################*/
void TPrinterDevice::DeviceName(char *Name, int MaxLen) const
{
	strncpy(Name,"Printer device",MaxLen);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::Add
#
#   Purpose....: Add object to wait
#
#   In params..: wait
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPrinterDevice::Add(TWait *Wait)
{
}

/*##########################################################################
#
#   Name       : TPrinterDevice::IsOnline
#
#   Purpose....: Check if online (and not in error-condition)
#
#   Returns....: TRUE if online
#
##########################################################################*/
int TPrinterDevice::IsOnline() const
{
    return RdosIsPrinterOk(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::IsJammed
#
#   Purpose....: Check if jammed
#
#   Returns....: TRUE if jammed
#
##########################################################################*/
int TPrinterDevice::IsJammed()
{
    return RdosIsPrinterJammed(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::IsPaperLow
#
#   Purpose....: Check if paper is low
#
#   Returns....: TRUE if paper low
#
##########################################################################*/
int TPrinterDevice::IsPaperLow()
{
    return RdosIsPrinterPaperLow(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::IsPaperEnd
#
#   Purpose....: Check if paper is end
#
#   Returns....: TRUE if paper end
#
##########################################################################*/
int TPrinterDevice::IsPaperEnd()
{
    return RdosIsPrinterPaperEnd(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::IsPrintHeadLifted
#
#   Purpose....: Check if head is lifted
#
#   Returns....: TRUE if printer head lifted
#
##########################################################################*/
int TPrinterDevice::IsPrintHeadLifted()
{
    return RdosIsPrinterHeadLifted(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::HasPaperInPresenter
#
#   Purpose....: Check if there is paper in presenter
#
#   Returns....: TRUE if paper in presenter
#
##########################################################################*/
int TPrinterDevice::HasPaperInPresenter()
{
    return RdosHasPrinterPaperInPresenter(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::PrintTest
#
#   Purpose....: Make a test printout
#
##########################################################################*/
void TPrinterDevice::PrintTest()
{
    RdosPrintTest(FHandle);
}

/*##########################################################################
#
#   Name       : TPrinterDevice::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPrinterDevice::SignalNewData()
{
}
