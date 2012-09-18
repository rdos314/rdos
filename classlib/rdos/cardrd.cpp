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
# cardrd.cpp
# Card reader device class
#
########################################################################*/

#include <string.h>
#include "cardrd.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TCardReaderDevice::TCardReaderDevice
#
#   Purpose....: Constructor
#
#   In params..: IniSection Parameter section
#                Port       port number (ie first printer = 1)
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCardReaderDevice::TCardReaderDevice(const char *IniSection, int Port)
        : TDevice(IniSection)
{
        Init(Port);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::TCardReaderDevice
#
#   Purpose....: Constructor
#
#   In params..: Port       port number (ie first printer = 1)
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCardReaderDevice::TCardReaderDevice(int Port)
{
        Init(Port);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::~TCardReaderDevice
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCardReaderDevice::~TCardReaderDevice()
{
    if (FHandle)
        RdosCloseCardDev(FHandle);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::Init
#
#   Purpose....: Init device
#
#   In params..: Port       port number (ie first printer = 1)
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCardReaderDevice::Init(int Port)
{
    char str[512];

    FPort = Port - 1;
    FHandle = RdosOpenCardDev(FPort);

    if (!RdosGetCardDevName(FHandle, str))
        strcpy(str, "Card reader device");
    
        Start(str, 0x2000);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::DeviceName
#
#   Purpose....: Returns device-name
#
#   In params..: MaxLen max size of name
#   Out params.: Name   device name
#   Returns....: *
#
##########################################################################*/
void TCardReaderDevice::DeviceName(char *Name, int MaxLen) const
{
    char str[512];

    if (RdosGetCardDevName(FHandle, str))
        strncpy(Name, str, MaxLen);
    else
        strncpy(Name,"Card reader device",MaxLen);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::IsOnline
#
#   Purpose....: Check if online (and not in error-condition)
#
#   Returns....: TRUE if online
#
##########################################################################*/
int TCardReaderDevice::IsOnline() const
{
    return RdosIsCardDevOk(FHandle);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::IsBusy
#
#   Purpose....: Check if busy
#
#   Returns....: TRUE if busy
#
##########################################################################*/
int TCardReaderDevice::IsBusy() const
{
    return RdosIsCardDevBusy(FHandle);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::IsCardInserted
#
#   Purpose....: Check if card is inserted
#
#   Returns....: TRUE if card inserted
#
##########################################################################*/
int TCardReaderDevice::IsCardInserted() const
{
    return RdosIsCardDevInserted(FHandle);
}

/*##########################################################################
#
#   Name       : TCardReaderDevice::Execute
#
#   Purpose....: Execute card reader
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCardReaderDevice::Execute()
{
    char Strip[40];
    
    while (FInstalled)
    {
        if (RdosWaitForCard(FHandle, Strip))
        {
            if (GoodCard)
                (*GoodCard)(this, Strip);
        }
        else
        {
            if (RdosIsCardDevOk(FHandle))
            {
                if (BadCard)
                    (*BadCard)(this);
            }
            else
                RdosWaitMilli(1000);
        } 
    }
}
