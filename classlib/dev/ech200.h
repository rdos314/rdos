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
# ech200.h
# ECH2xx based heat pump
#
########################################################################*/

#ifndef _ECH200_H
#define _ECH200_H

#include "thread.h"
#include "modbus.h"

class TEch200 : public TThread
{
public:
    TEch200(TModbusDevice *moddev, int address);
    virtual ~TEch200();

    void UpdateHeatIn();

    void SetHeatLimit(int Limit);
    void SetColdLimit(int Limit);

    bool IsHeatLimitUpdated();
    bool IsColdLimitUpdated();

    int GetHeatInlet();
    int GetHeatOutlet();
    int GetColdInlet();
    int GetOperTime();
    int GetAutoAlarms();
    int GetManualAlarms();
    bool IsOn();

protected:
    int ReadParam(int index);
    void WriteParam(int index, int val);
    int ReadInput(int index);
    virtual void Execute();

    bool FCooling;
    bool FHeating;
    bool FOn;

    int FColdSet;
    bool FUpdateCold;
    int FColdLimit;

    int FHeatSet;
    bool FUpdateHeat;
    int FHeatLimit;

    bool FUpdateHeatIn;

    int FHeatInlet;
    int FHeatOutlet;
    int FColdInlet;
    int FOperTime;
    int FAutoAlarms;
    int FManualAlarms;

    TModbus FModbus;

};

#endif

