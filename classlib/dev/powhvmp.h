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
    int GetMaxChargeCurrent();
    int GetMaxGridChargeCurrent();

    void SetOutputPrio(int prio);
    void SetChargePrio(int prio);
    void SetMaxChargeCurrent(int i);
    void SetMaxGridChargeCurrent(int i);

    long double GetGridVoltage();
    long double GetGridFrequency();
    long double GetGridPower();
    long double GetGridEnergy();

    long double GetOutputVoltage();
    long double GetOutputCurrent();
    long double GetOutputFrequency();
    long double GetOutputPower();
    long double GetOutputEnergy();

    long double GetSolarVoltage();
    long double GetSolarCurrent();
    long double GetSolarPower();
    long double GetSolarEnergy();

    long double GetBatteryVoltage();
    long double GetBatteryCurrent();
    long double GetBatteryPower();
    long double GetBatteryChargeEnergy();
    long double GetBatteryDischargeEnergy();
    long double GetBatterySoc();

    int GetDcDcTemperature();
    int GetInverterTemperature();

protected:
    void WriteReg(int reg, int val);
    bool GetData();
    void HandleParam();
    virtual void Execute();

    bool FOnline;
    bool FHasData;
    bool FUp;
    bool FFirst;
    bool FChangeMaxGridCurrent;
    TFile *FLogFile;

    int FMode;

    long double FGridVoltage;
    long double FGridFrequency;
    long double FGridPower;
    long double FGridEnergy;

    long double FOutputVoltage;
    long double FOutputCurrent;
    long double FOutputFrequency;
    long double FOutputPower;
    long double FOutputEnergy;

    long double FSolarVoltage;
    long double FSolarCurrent;
    long double FSolarPower;
    long double FSolarEnergy;

    long double FBatteryVoltage;
    long double FBatteryCurrent;
    long double FBatteryPower;
    long double FBatteryChargeEnergy;
    long double FBatteryDischargeEnergy;
    long double FBatteryVc;
    long double FBatterySoc;

    int FOutputPrio;
    int FChargePrio;

    int FMaxChargeCurrent;
    int FMaxGridChargeCurrent;

    int FDcDcTemp;
    int FInverterTemp;

    TModbus FModbus;
    TRdosLog FLog;

};

#endif

