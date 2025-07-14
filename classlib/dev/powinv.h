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
# powinv.h
# Smart power electronics inverter class
#
########################################################################*/

#ifndef _POWINV_H
#define _POWINV_H

#include "sockobj.h"
#include "thread.h"

class TSmartPowInverter : public TThread
{
public:
    TSmartPowInverter(char *HostStr);
    virtual ~TSmartPowInverter();

    bool IsOnline();

    void GetCurrentState(char *buf);
    void GetCurrentError(char *buf);
    long double GetCurrentGrid();
    long double GetCurrentDump();
    long double GetCurrentRpm();
    long double GetDayEnergy();
    long double GetTotalEnergy();

    void (*OnState)(TSmartPowInverter *Device, const char *buf);
    void (*OnError)(TSmartPowInverter *Device, const char *buf);
    void (*OnGridPower)(TSmartPowInverter *Device, long double val);
    void (*OnDumpPower)(TSmartPowInverter *Device, long double val);
    void (*OnRpm)(TSmartPowInverter *Device, long double val);
    void (*OnDayEnergy)(TSmartPowInverter *Device, long double val);


protected:
    char *FindTag(char *str, const char *tag);
    char *GetValue(char *str);
    void ConvertFloat(char *str);
    void HandleTr(char *str);
    void HandleTable(char *str);

    void NotifyData(char *Tag, char *Value, char *Unit);

    virtual void Execute();

    char FCurrState[40];
    char FCurrError[40];
    long double FCurrGrid;
    long double FCurrDump;
    long double FCurrRpm;
    long double FDayE;
    long double FTotalE;

    bool FOnline;
    long FIP;
    char *FHostStr;
    TTcpSocket *FSocket;
    char FBuf[8192];

};

#endif

