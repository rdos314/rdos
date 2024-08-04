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
# powhvmp.cpp
# POW-HVMxx-xx-P based inverter
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include "rdos.h"
#include "powhvmp.h"

/*##########################################################################
#
#   Name       : TPowHvmP::TPowHvmP
#
#   Purpose....: TPowHvmP constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPowHvmP::TPowHvmP(TModbusDevice *moddev, int address)
  : FModbus(moddev, address)
{
    FOnline = false;
    FHasData = false;
    FLogFile = 0;
    ClearEnergy();

    Start("POW-HVM-P", 0x8000);
}

/*##########################################################################
#
#   Name       : TPowHvmP::~TPowHvmP
#
#   Purpose....: TPowHvmP destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPowHvmP::~TPowHvmP()
{
}

/*##########################################################################
#
#   Name       : TPowHvmP::StartLog
#
#   Purpose....: Start log
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPowHvmP::StartLog(const char *path)
{
    int num;
    int handle;
    char FileName[80];

    for (num = 0; num < 10000; num++)
    {
        sprintf(FileName, "%s/log%04d.dat", path, num);
        handle = RdosOpenFile(FileName, 0);
        if (handle)
            RdosCloseFile(handle);
        else
            break;
    }
    FLogFile = new TFile(FileName, 0);
}

/*##########################################################################
#
#   Name       : TPowHvmP::HasNewData
#
#   Purpose....: Check for new data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPowHvmP::HasNewData()
{
    return FHasData;
}

/*##########################################################################
#
#   Name       : TPowHvmP::ClearNewData
#
#   Purpose....: Clear new data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPowHvmP::ClearNewData()
{
    FHasData = false;
}

/*##########################################################################
#
#   Name       : TPowHvmP::ClearEnergy
#
#   Purpose....: Clear energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPowHvmP::ClearEnergy()
{
    FGridEnergy = 0;
    FOutputEnergy = 0;
    FSolarEnergy = 0;
    FBatteryChargeEnergy = 0;
    FBatteryDischargeEnergy = 0;
}

/*##########################################################################
#
#   Name       : TPowHvmP::IsOnline
#
#   Purpose....: Check online
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPowHvmP::IsOnline()
{
    return FOnline;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetMode
#
#   Purpose....: Get operation mode
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPowHvmP::GetMode()
{
    return FMode;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetGridVoltage
#
#   Purpose....: Get grid voltage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetGridVoltage()
{
    return FGridVoltage;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetGridFrequency
#
#   Purpose....: Get grid frequency
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetGridFrequency()
{
    return FGridFrequency;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetGridPower
#
#   Purpose....: Get grid power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetGridPower()
{
    return FGridPower;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetGridEnergy
#
#   Purpose....: Get grid energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetGridEnergy()
{
    return FGridEnergy;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetOutputVoltage
#
#   Purpose....: Get output voltage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetOutputVoltage()
{
    return FOutputVoltage;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetOutputCurrent
#
#   Purpose....: Get output current
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetOutputCurrent()
{
    return FOutputCurrent;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetOutputFrequency
#
#   Purpose....: Get output frequency
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetOutputFrequency()
{
    return FOutputFrequency;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetOutputPower
#
#   Purpose....: Get output power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetOutputPower()
{
    return FOutputPower;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetOutputEnergy
#
#   Purpose....: Get output energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetOutputEnergy()
{
    return FOutputEnergy;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetSolarVoltage
#
#   Purpose....: Get solar voltage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetSolarVoltage()
{
    return FSolarVoltage;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetSolarCurrent
#
#   Purpose....: Get solar current
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetSolarCurrent()
{
    return FSolarCurrent;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetSolarPower
#
#   Purpose....: Get solar power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetSolarPower()
{
    return FSolarPower;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetSolarEnergy
#
#   Purpose....: Get solar energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetSolarEnergy()
{
    return FSolarEnergy;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetBatteryVoltage
#
#   Purpose....: Get battery voltage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetBatteryVoltage()
{
    return FBatteryVoltage;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetBatteryCurrent
#
#   Purpose....: Get battery current
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetBatteryCurrent()
{
    return FBatteryCurrent;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetBatteryPower
#
#   Purpose....: Get battery power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetBatteryPower()
{
    return FBatteryPower;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetBatteryChargeEnergy
#
#   Purpose....: Get battery charge energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetBatteryChargeEnergy()
{
    return FBatteryChargeEnergy;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetBatteryDischargeEnergy
#
#   Purpose....: Get battery discharge energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetBatteryDischargeEnergy()
{
    return FBatteryDischargeEnergy;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetDcDcTemperature
#
#   Purpose....: Get DCDC temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPowHvmP::GetDcDcTemperature()
{
    return FDcDcTemp;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetInverterTemperature
#
#   Purpose....: Get inverter temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPowHvmP::GetInverterTemperature()
{
    return FInverterTemp;
}

/*##########################################################################
#
#   Name       : TPowHvmP::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPowHvmP::Execute()
{
    bool ok;
    int val;
    int i;
    TString str;

    for (;;)
    {
        ok = FModbus.ReqHoldingRegisters(40202, 27);

        if (ok)
        {
            FModbus.GetBufferedHoldingRegister(40202, &val);
            FMode = val;

            FModbus.GetBufferedHoldingRegister(40203, &val);
            FGridVoltage = (double)val / 10.0;

            FModbus.GetBufferedHoldingRegister(40204, &val);
            FGridFrequency = (double)val / 100.0;

            FModbus.GetBufferedHoldingRegister(40205, &val);
            FGridPower = (double)val;
            FGridEnergy += FGridPower / 60.0;

            FModbus.GetBufferedHoldingRegister(40211, &val);
            FOutputVoltage = (double)val / 10.0;

            FModbus.GetBufferedHoldingRegister(40212, &val);
            FOutputCurrent = (double)val / 10.0;

            FModbus.GetBufferedHoldingRegister(40213, &val);
            FOutputFrequency = (double)val / 100.0;

            FModbus.GetBufferedHoldingRegister(40214, &val);
            FOutputPower = (double)val;
            FOutputEnergy += FOutputPower / 60.0;

            FModbus.GetBufferedHoldingRegister(40216, &val);
            FBatteryVoltage = (double)val / 10.0;

            FModbus.GetBufferedHoldingRegister(40217, &val);
            FBatteryCurrent = (double)val / 10.0;

            FModbus.GetBufferedHoldingRegister(40218, &val);
            FBatteryPower = (double)val;

            if (FBatteryCurrent > 0.0)
                FBatteryChargeEnergy += FBatteryPower / 60.0;
            else
                FBatteryDischargeEnergy += FBatteryPower / 60.0;

            FModbus.GetBufferedHoldingRegister(40220, &val);
            FSolarVoltage = (double)val / 10.0;

            FModbus.GetBufferedHoldingRegister(40221, &val);
            FSolarCurrent = (double)val / 10.0;

            FModbus.GetBufferedHoldingRegister(40224, &val);
            FSolarPower = (double)val;
            FSolarEnergy += FSolarPower / 60.0;

            FModbus.GetBufferedHoldingRegister(40227, &val);
            FDcDcTemp = val;

            FModbus.GetBufferedHoldingRegister(40228, &val);
            FInverterTemp = val;

            FHasData = true;

            if (FLogFile)
            {
                TDateTime time;

                str.printf("%04d-%02d-%02d %02d.%02d Mode %d Grid: %6.1LfV %5dW Output: %6.1LfV %5.1LfA %5dW Solar: %6.1LfV %5.1LfA %5dW Battery: %6.1LfV %5.1LfA %5dW Temp %d %d\r\n",
                                            time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(),
                                            FMode,
                                            FGridVoltage, (int)FGridPower,
                                            FOutputVoltage, FOutputCurrent, (int)FOutputPower,
                                            FSolarVoltage, FSolarCurrent, (int)FSolarPower,
                                            FBatteryVoltage, FBatteryCurrent, (int)FBatteryPower,
                                            FDcDcTemp, FInverterTemp);
                FLogFile->Write(str.GetData(), str.GetSize());
            }
        }

        FOnline = ok;

        if (ok)
            for (i = 0; i < 60; i++)
                RdosWaitMilli(1000);
        else
            RdosWaitMilli(1000);
    }
}
