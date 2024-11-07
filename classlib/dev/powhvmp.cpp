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
  : FModbus(moddev, address),
    FLog("PowHvmP")
{
    FOnline = false;
    FHasData = false;
    FUp = true;
    FFirst = true;
    FChangeMaxGridCurrent = false;
    FLogFile = 0;
    ClearEnergy();

    FModbus.DisableRetries();

    FOutputPrio = -1;
    FChargePrio = -1;
    FMaxChargeCurrent = -1;
    FMaxGridChargeCurrent = -1;

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
        handle = RdosOpenHandle(FileName, O_RDWR);
        if (handle > 0)
            RdosCloseHandle(handle);
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
#   Name       : TPowHvmP::GetBatterySoc
#
#   Purpose....: Get battery state of charge
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TPowHvmP::GetBatterySoc()
{
    return FBatterySoc;
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
#   Name       : TPowHvmP::GetOutputPrio
#
#   Purpose....: Get output prio
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPowHvmP::GetOutputPrio()
{
    return FOutputPrio;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetChargePrio
#
#   Purpose....: Get charge prio
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPowHvmP::GetChargePrio()
{
    return FChargePrio;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetMaxChargeCurrent
#
#   Purpose....: Get max charge current
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPowHvmP::GetMaxChargeCurrent()
{
    return FMaxChargeCurrent;
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetMaxGridChargeCurrent
#
#   Purpose....: Get max grid charge current
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPowHvmP::GetMaxGridChargeCurrent()
{
    return FMaxGridChargeCurrent;
}

/*##########################################################################
#
#   Name       : TPowHvmP::SetOutputPrio
#
#   Purpose....: Set output prio
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPowHvmP::SetOutputPrio(int prio)
{
    FOutputPrio = prio;
}

/*##########################################################################
#
#   Name       : TPowHvmP::SetChargePrio
#
#   Purpose....: Set charge prio
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPowHvmP::SetChargePrio(int prio)
{
    FChargePrio = prio;
}

/*##########################################################################
#
#   Name       : TPowHvmP::SetMaxChargeCurrent
#
#   Purpose....: Set max charge current
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPowHvmP::SetMaxChargeCurrent(int i)
{
    FMaxChargeCurrent = i;
}

/*##########################################################################
#
#   Name       : TPowHvmP::SetMaxGridChargeCurrent
#
#   Purpose....: Set max grid charge current
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPowHvmP::SetMaxGridChargeCurrent(int i)
{
    int nval = i / 2;
    int cval = FMaxGridChargeCurrent / 2;

    if (nval > cval)
    {
        if (FUp)
        {
            FMaxGridChargeCurrent = i;
            FChangeMaxGridCurrent = true;
        }
        else
        {
            if (nval - cval > 1)
            {
                FUp = true;
                FMaxGridChargeCurrent = i;
                FChangeMaxGridCurrent = true;
            }
        }
    }
    else
    {
        if (nval < cval)
        {
            if (FUp)
            {
                if (cval - nval > 1)
                {
                    FUp = false;
                    FMaxGridChargeCurrent = i;
                    FChangeMaxGridCurrent = true;
                }
            }
            else
            {
                FMaxGridChargeCurrent = i;
                FChangeMaxGridCurrent = true;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TPowHvmP::WriteReg
#
#   Purpose....: Write register
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPowHvmP::WriteReg(int reg, int val)
{
    FModbus.StartWritePresetRegisters(reg, 1, val);
    FModbus.AddPresetRegister(reg, val);
    FModbus.DoWritePresetRegisters();
}

/*##########################################################################
#
#   Name       : TPowHvmP::GetData
#
#   Purpose....: Get messure data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPowHvmP::GetData()
{
    bool ok;
    int val;
    TString str;

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
        FGridEnergy += FGridPower / 60.0 / 4.0;

        FModbus.GetBufferedHoldingRegister(40211, &val);
        FOutputVoltage = (double)val / 10.0;

        FModbus.GetBufferedHoldingRegister(40212, &val);
        FOutputCurrent = (double)val / 10.0;

        FModbus.GetBufferedHoldingRegister(40213, &val);
        FOutputFrequency = (double)val / 100.0;

        FModbus.GetBufferedHoldingRegister(40214, &val);
        FOutputPower = (double)val;
        FOutputEnergy += FOutputPower / 60.0 / 4.0;

        FModbus.GetBufferedHoldingRegister(40216, &val);
        FBatteryVoltage = (double)val / 10.0;

        FModbus.GetBufferedHoldingRegister(40217, &val);
        FBatteryCurrent = (double)val / 10.0;

        FModbus.GetBufferedHoldingRegister(40220, &val);
        FSolarVoltage = (double)val / 10.0;

        FModbus.GetBufferedHoldingRegister(40221, &val);
        FSolarCurrent = (double)val / 10.0;

        FModbus.GetBufferedHoldingRegister(40224, &val);
        FSolarPower = (double)val;
        FSolarEnergy += FSolarPower / 60.0 / 4.0;

        FModbus.GetBufferedHoldingRegister(40227, &val);
        FDcDcTemp = val;

        FModbus.GetBufferedHoldingRegister(40228, &val);
        FInverterTemp = val;

        if (FFirst)
            FBatteryVc = FBatteryVoltage - 0.038 * FBatteryCurrent;
        else
            FBatteryVc = 0.95 * FBatteryVc + 0.05 * (FBatteryVoltage - 0.038 * FBatteryCurrent);

        FBatteryPower = FBatteryVc * FBatteryCurrent;

        if (FBatteryCurrent > 0.0)
            FBatteryChargeEnergy += FBatteryPower / 60.0 / 4.0;
        else
            FBatteryDischargeEnergy += FBatteryPower / 60.0 / 4.0;

        FBatterySoc = (FBatteryVc - 45.6) / 7.4;

        FHasData = true;
        FFirst = false;

        if (FLogFile)
        {
            TDateTime time;

            str.printf("%04d-%02d-%02d %02d.%02d Mode %d Grid: %6.1LfV %5dW Output: %6.1LfV %5.1LfA %5dW Solar: %6.1LfV %5.1LfA %5dW Battery: %6.1LfV %5.1LfA %5dW Temp %d %d Calc: %6.1LfV %5.1Lf%%\r\n",
                                        time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(),
                                        FMode,
                                        FGridVoltage, (int)FGridPower,
                                        FOutputVoltage, FOutputCurrent, (int)FOutputPower,
                                        FSolarVoltage, FSolarCurrent, (int)FSolarPower,
                                        FBatteryVoltage, FBatteryCurrent, (int)FBatteryPower,
                                        FDcDcTemp, FInverterTemp,
                                        FBatteryVc, 100.0 * FBatterySoc);
            FLogFile->Write(str.GetData(), str.GetSize());
        }
    }
    return ok;
}

/*##########################################################################
#
#   Name       : TPowHvmP::HandleParam
#
#   Purpose....: Handle parameters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPowHvmP::HandleParam()
{
    int val;
    bool ChangeOutputPrio = false;
    bool ChangeChargePrio = false;
    bool ChangeChargeCurrent = false;

    if (FModbus.ReadHoldingRegister(40302, &val))
    {
        if (FOutputPrio >= 0)
        {
            if (FOutputPrio != val)
                ChangeOutputPrio = true;
        }
        else
            FOutputPrio = val;
    }

    if (FModbus.ReqHoldingRegisters(40332, 3))
    {
        FModbus.GetBufferedHoldingRegister(40332, &val);
        if (FChargePrio >= 0)
        {
            if (FChargePrio != val)
                ChangeChargePrio = true;
        }
        else
            FChargePrio = val;

        FModbus.GetBufferedHoldingRegister(40333, &val);
        if (FMaxChargeCurrent >= 0)
        {
            val = val / 10;
            if (val != FMaxChargeCurrent)
                ChangeChargeCurrent = true;
        }
        else
            FMaxChargeCurrent = val / 10;

        FModbus.GetBufferedHoldingRegister(40334, &val);
        if (!FChangeMaxGridCurrent)
        {
            if (10 * FMaxGridChargeCurrent != val)
                FLog.printf(0, "HandleParam", "Change of max grid current from %d A to %d A failed", val / 10, FMaxGridChargeCurrent);
            FMaxGridChargeCurrent = val / 10;
        }
    }

    if (ChangeOutputPrio)
    {
        switch (FOutputPrio)
        {
            case 0:
                FLog.Log(0, "HandleParam", "Change output prio to: Utility-PV-batt");
                break;

            case 1:
                FLog.Log(0, "HandleParam", "Change output prio to: PV-Utility-Battery");
                break;

            case 2:
                FLog.Log(0, "HandleParam", "Change output prio to: PV-Battery-Utility");
                break;
        }
        WriteReg(40302, FOutputPrio);
    }

    if (ChangeChargePrio)
    {
        switch (FChargePrio)
        {
            case 0:
                FLog.Log(0, "HandleParam", "Change charge prio to: Utility priority");
                break;

            case 1:
                FLog.Log(0, "HandleParam", "Change charge prio to: PV priority");
                break;

            case 2:
                FLog.Log(0, "HandleParam", "Change charge prio to: PV at the same level as Utility");
                break;

            case 3:
                FLog.Log(0, "HandleParam", "Change charge prio to: Only PV charging");
                break;
        }
        WriteReg(40332, FChargePrio);
    }

    if (ChangeChargeCurrent)
    {
        FLog.printf(0, "HandleParam", "Change charge current to %d A", FMaxChargeCurrent);
        WriteReg(40333, 10 * FMaxChargeCurrent);
    }

    if (FChangeMaxGridCurrent)
    {
        FChangeMaxGridCurrent = false;
        FLog.printf(0, "HandleParam", "Change grid charge current to %d A", FMaxGridChargeCurrent);
        WriteReg(40334, 10 * FMaxGridChargeCurrent);
    }
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
    TDateTime ref;
    int year = ref.GetYear();
    int month = ref.GetMonth();
    int day = ref.GetDay();
    int hour = ref.GetHour();
    int min = ref.GetMin();
    int sec = 15 * (ref.GetSec() / 15) + 5;
    TDateTime curr(year, month, day, hour, min, sec);

    RdosWaitMilli(250);

    for (;;)
    {
        curr.WaitUntilExpired();
        FOnline = GetData();
        HandleParam();
        curr.AddSec(15);
    }
}
