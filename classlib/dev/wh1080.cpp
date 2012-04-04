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
# wh1080.cpp
# WH1080 weather station device class
#
########################################################################*/

#include <string.h>

#include "wh1080.h"
#include "rdos.h"

#define     FALSE	0
#define     TRUE	!FALSE

/*##########################################################################
#
#   Name       : TWh1080Device::TWh1080Device
#
#   Purpose....: Constructor for TWh1080Device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWh1080Device::TWh1080Device()
  : THidDevice(0x1941, 0x8021)
{
}

/*##########################################################################
#
#   Name       : TWh1080Device::~TWh1080Device
#
#   Purpose....: Destructor for TWh1080Device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWh1080Device::~TWh1080Device()
{
}

/*##########################################################################
#
#   Name       : TWh1080Device::DeviceName
#
#   Purpose....: Return device-name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWh1080Device::DeviceName(char *Name, int MaxLen) const
{
    strncpy(Name, "WH1080", MaxLen);
}

/*##########################################################################
#
#   Name       : TWh1080Device::ReadBlock
#
#   Purpose....: Read block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::ReadBlock(int Offset, char *Buffer)
{
    char req[8];

    req[0] = 0xA1;
    req[1] = (char)(Offset / 256);
    req[2] = (char)(Offset & 0xFF);
    req[3] = 0x20;
    req[4] = 0xA1;
    req[5] = (char)(Offset / 256);
    req[6] = (char)(Offset & 0xFF);
    req[7] = 0x20;

    if (Write(req, 8))
        if (Read(Buffer, 32, 1000))
            return TRUE;

    return FALSE;
}

/*##########################################################################
#
#   Name       : TWh1080Device::WriteBlock
#
#   Purpose....: Write block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::WriteBlock(int Offset, const char *Buffer)
{
    char req[8];

    req[0] = 0xA0;
    req[1] = (char)(Offset / 256);
    req[2] = (char)(Offset & 0xFF);
    req[3] = 0x20;
    req[4] = 0xA0;
    req[5] = (char)(Offset / 256);
    req[6] = (char)(Offset & 0xFF);
    req[7] = 0x20;

    if (Write(req, 8))
        if (Write(Buffer, 32))
            if (Read(req, 8, 1000))
                return TRUE;
        
    return FALSE;
}

/*##########################################################################
#
#   Name       : TWh1080Device::WriteDataRefresh
#
#   Purpose....: Write data refresh
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::WriteDataRefresh()
{
    char req[8];

    req[0] = 0xA2;
    req[1] = 0;
    req[2] = 0x1A;
    req[3] = 0x20;
    req[4] = 0xA2;
    req[5] = 0xAA;
    req[6] = 0;
    req[7] = 0x20;

    if (Write(req, 8))
        if (Read(req, 8, 1000))
            return TRUE;
        
    return FALSE;
}

/*##########################################################################
#
#   Name       : TWh1080Device::ReadFixedBlock
#
#   Purpose....: Read fixed block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::ReadFixedBlock(char *Buffer)
{
    unsigned char ch0, ch1;

    if (ReadBlock(0, Buffer))
    {
        ch0 = (unsigned char)Buffer[0];
        ch1 = (unsigned char)Buffer[1];
    
        if (ch0 == 0x55 && ch1 == 0xAA)
            return TRUE;

        if (ch0 == 0xFF && ch1 == 0xFF)
            return TRUE;

        if (ch0 == 0x55 && ch1 == 0x55)
            return TRUE;
    }

    return FALSE;
}

/*##########################################################################
#
#   Name       : TWh1080Device::WriteFixedBlock
#
#   Purpose....: Write fixed block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWh1080Device::WriteFixedBlock(char *Buffer)
{
    Buffer[0] = 0x55;
    Buffer[1] = 0xAA;

    if (WriteBlock(0, Buffer))
        if (WriteDataRefresh())
            return TRUE;

    return FALSE;
}
