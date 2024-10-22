/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-20019, Leif Ekblad
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
# powhvmp.h
# POW-HVMxx-xx-P based inverter
#
########################################################################*/

#ifndef _POWHVMP_H
#define _POWHVMP_H

#include "thread.h"
#include "modbus.h"
#include "rdoslog.h"

class TPowHvmP : public TThread
{
public:
    TPowHvmP(TModbusDevice *moddev, int address);
    virtual ~TPowHvmP();

    bool IsOnline();

    void StartLog(const char *path);

    bool HasNewData();
    void ClearNewData();
    void ClearEnergy();

    int GetMode();
    int GetOutputPrio();
    int GetChargePrio();
    double GetMaxChargeCurrent();
    double GetMaxGridChargeCurrent();

    void SetOutputPrio(int prio);
    void SetChargePrio(int prio);
    void SetMaxChargeCurrent(double i);
    void SetMaxGridChargeCurrent(double i);

    double GetGridVoltage();
    double GetGridFrequency();
    double GetGridPower();
    double GetGridEnergy();

    double GetOutputVoltage();
    double GetOutputCurrent();
    double GetOutputFrequency();
    double GetOutputPower();
    double GetOutputEnergy();

    double GetSolarVoltage();
    double GetSolarCurrent();
    double GetSolarPower();
    double GetSolarEnergy();

    double GetBatteryVoltage();
    double GetBatteryCurrent();
    double GetBatteryPower();
    double GetBatteryChargeEnergy();
    double GetBatteryDischargeEnergy();
    double GetBatterySoc();

    int GetDcDcTemperature();
    int GetInverterTemperature();

protected:
    void WriteReg(int reg, int val);
    virtual void Execute();

    bool FOnline;
    bool FHasData;
    TFile *FLogFile;

    int FMode;

    double FGridVoltage;
    double FGridFrequency;
    double FGridPower;
    double FGridEnergy;

    double FOutputVoltage;
    double FOutputCurrent;
    double FOutputFrequency;
    double FOutputPower;
    double FOutputEnergy;

    double FSolarVoltage;
    double FSolarCurrent;
    double FSolarPower;
    double FSolarEnergy;

    double FBatteryVoltage;
    double FBatteryCurrent;
    double FBatteryPower;
    double FBatteryChargeEnergy;
    double FBatteryDischargeEnergy;
    double FBatteryVc;
    double FBatterySoc;

    int FOutputPrio;
    int FChargePrio;

    double FMaxChargeCurrent;
    double FMaxGridChargeCurrent;

    int FDcDcTemp;
    int FInverterTemp;

    TModbus FModbus;
    TRdosLog FLog;

};

#endif

