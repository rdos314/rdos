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
# vp.h
# Heat pump class
#
########################################################################*/

#ifndef VP_H
#define VP_H

#include "file.h"
#include "fuzzy.h"
#include "control.h"
#include "rdoslog.h"
#include "ech200.h"
#include "ocppdev.h"
#include "hhcn818.h"

#define POWER_COUNT          30

class TVp : public TFuzzy
{
public:
    TVp(TControlThread *control, TOcppNotify *ocpp, THhcRelay *relay);
    ~TVp();

    void DeviceName(char *Name, int Size) const;

    int GetTankTemp();

    void SetMaxMotor(int motor);
    void SetPower(long double val);
    void SetTempError(int temp);
    void SetAmbient(int ref, int ambient, bool night);

protected:
    void SetupCheckDelay();
    void UpdateCirc();
    void UpdateVp();
    void WriteCircValve(long double value);

    void GetTemp(char *str);
    void GetTank(char *str);
    void GetCirc(char *str);
    void GetOn(char *str);
    void CreateDayFile(int year, int month, int day);
    void UpdateDataStore(int hour, int min);

    virtual void Execute();

    int TempSum;
    int TempCount;

    int FMotorCount;
    int FMotorSum;

    long double FPowerArr[POWER_COUNT];
    long double FPowerSum;
    int FCurrPower;
    int FPowerCount;
    int FPowerIndex;

    int FValidCirc;
    int FCirc;
    int FIncCount;
    int FHasCirc;
    long double FCircSpeed;
    bool FVpCircOn;

    int FLowTemp;

    int FCheckDelay;

    int FStartTimeout;

    int FTankTemp;

    long double FCurrTemp;

    TFile *FDayFile;

    int FValidAmbient;
    int FAmbient;
    int FRef;

    int FMaxTank;

    TControlThread *FControl;
    TOcppNotify *FOcpp;
    THhcRelay *FRelay;

    TSerialDevice FSerial;
    TModbusDevice FModDev;
    TEch200 FEch;

    TSection FSection;
    TRdosLog FLog;
};

#endif
