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

    FUpdateHeat = false;
    FUpdateCold = false;
    FUpdateHeatIn = false;

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
#   Name       : TEch200::UpdateHeatIn
#
#   Purpose....: Force read heat in
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TEch200::UpdateHeatIn()
{
    FUpdateHeatIn = true;
}

/*##########################################################################
#
#   Name       : TEch200::SetHeatLimit
#
#   Purpose....: Set heat limit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TEch200::SetHeatLimit(int Limit)
{
    if (Limit < 250)
        Limit = 250;

    if (Limit > 500)
        Limit = 500;

    FHeatLimit = Limit;
    FUpdateHeat = true;
}

/*##########################################################################
#
#   Name       : TEch200::SetColdLimit
#
#   Purpose....: Set cold limit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TEch200::SetColdLimit(int Limit)
{
    if (Limit < 100)
        Limit = 100;

    if (Limit > 250)
        Limit = 250;

    FColdLimit = Limit;
    FUpdateCold = true;
}

/*##########################################################################
#
#   Name       : TEch200::IsHeatLimitUpdated
#
#   Purpose....: Is heat limit updated
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TEch200::IsHeatLimitUpdated()
{
    return FUpdateHeat;
}

/*##########################################################################
#
#   Name       : TEch200::IsColdLimitUpdated
#
#   Purpose....: Is cold limit updated
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TEch200::IsColdLimitUpdated()
{
    return FUpdateCold;
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
#   Name       : TEch200::WriteParam
#
#   Purpose....: Write param
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TEch200::WriteParam(int index, int val)
{
    int reg;

    reg = 40001 + 2048 + index;
    FModbus.StartWritePresetRegisters(reg, 1, val);
    FModbus.AddPresetRegister(reg, val);
    FModbus.DoWritePresetRegisters();
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
        if (FUpdateCold)
        {
            if (FColdSet != FColdLimit)
                WriteParam(1, FColdLimit);

            FColdSet = ReadParam(1);
            if (FColdSet == FColdLimit)
                FUpdateCold = false;
        }

        if (FUpdateHeat)
        {
            if (FHeatSet != FHeatLimit)
                WriteParam(2, FHeatLimit);

            FHeatSet = ReadParam(2);
            if (FHeatSet == FHeatLimit)
                FUpdateHeat = false;
        }

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

            FColdSet = ReadParam(1);
            FHeatSet = ReadParam(2);
        }
        else
        {
            if (FUpdateHeatIn)
            {
                FUpdateHeatIn = false;

                high = ReadInput(0x46E);
                low = ReadInput(0x46F);
                FHeatInlet = high * 256 + low;
            }
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
