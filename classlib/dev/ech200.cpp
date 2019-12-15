/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# ech200.cpp
# ECH2xx based heat pump
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include "rdos.h"
#include "ech200.h"

/*##########################################################################
#
#   Name       : TEch200::TEch200
#
#   Purpose....: ECH200 constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TEch200::TEch200(TModbusDevice *moddev, int address)
  : FModbus(moddev, address)
{
    FHeatInlet = 0;
    FHeatOutlet = 0;
    FColdInlet = 0;
    FOperTime = 0;
    FAutoAlarms = 0;
    FManualAlarms = 0;
    FCooling = false;
    FHeating = false;

    Start("ECH200", 0x8000);
}

/*##########################################################################
#
#   Name       : TEch200::~TEch200
#
#   Purpose....: ECH200 destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TEch200::~TEch200()
{
}

/*##########################################################################
#
#   Name       : TEch200::GetHeatInlet
#
#   Purpose....: Get heat inlet temp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TEch200::GetHeatInlet()
{
    return FHeatInlet;
}

/*##########################################################################
#
#   Name       : TEch200::GetHeatOutlet
#
#   Purpose....: Get heat outlet temp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TEch200::GetHeatOutlet()
{
    return FHeatOutlet;
}

/*##########################################################################
#
#   Name       : TEch200::GetColdInlet
#
#   Purpose....: Get cold inlet temp
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TEch200::GetColdInlet()
{
    return FColdInlet;
}

/*##########################################################################
#
#   Name       : TEch200::GetOperTime
#
#   Purpose....: Get operating hours
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TEch200::GetOperTime()
{
    return FOperTime;
}

/*##########################################################################
#
#   Name       : TEch200::GetAutoAlarms
#
#   Purpose....: Get auto alarms
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TEch200::GetAutoAlarms()
{
    return FAutoAlarms;
}

/*##########################################################################
#
#   Name       : TEch200::GetManualAlarms
#
#   Purpose....: Get manual alarms
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TEch200::GetManualAlarms()
{
    return FManualAlarms;
}

/*##########################################################################
#
#   Name       : TEch200::IsOn
#
#   Purpose....: Is on?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TEch200::IsOn()
{
    return FOn;
}

/*##########################################################################
#
#   Name       : TEch200::ReadParam
#
#   Purpose....: Read param
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TEch200::ReadParam(int index)
{
    int reg;

    reg = 40001 + 2048 + index;
    return FModbus.ReadHoldingRegister(reg);
}

/*##########################################################################
#
#   Name       : TEch200::ReadInput
#
#   Purpose....: Read input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TEch200::ReadInput(int index)
{
    int reg;

    reg = 40001 + 8 * 2048 + index - 0x4F;
    return FModbus.ReadHoldingRegister(reg);
}

/*##########################################################################
#
#   Name       : TEch200::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TEch200::Execute()
{
    int low;
    int mid;
    int high;
    int counter = 0;

    low = ReadInput(0x4A3);
    low = low & 7;

    switch (low)
    {
        case 5:
            FCooling = true;
            FHeating = false;
            break;

        case 6:
            FCooling = false;
            FHeating = true;
            break;

        default:
            FCooling = false;
            FHeating = false;
            break;
    }

    for (;;)
    {
        if ((counter % 30 == 0))
        {
            high = ReadInput(0x46E);
            low = ReadInput(0x46F);
            FHeatInlet = high * 256 + low;

            high = ReadInput(0x470);
            low = ReadInput(0x471);
            FHeatOutlet = high * 256 + low;

            high = ReadInput(0x472);
            low = ReadInput(0x473);
            FColdInlet = high * 256 + low;

            low = ReadInput(0x4BB);
            mid = ReadInput(0x4BC);
            high = ReadInput(0x4BD);
            FAutoAlarms = 65536 * high + 256 * mid + low;

            low = ReadInput(0x4BE);
            mid = ReadInput(0x4BF);
            high = ReadInput(0x4C0);
            FManualAlarms = 65536 * high + 256 * mid + low;
        }

        low = ReadInput(0x47A);
        if (low & 4)
            FOn = true;
        else
            FOn = false;

        if ((counter % 1800) == 0)
        {
            counter = 1;
            FOperTime = ReadInput(0x850);
        }
        else
            counter++;

        RdosWaitMilli(1000);
    }
}
