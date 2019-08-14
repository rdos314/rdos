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

