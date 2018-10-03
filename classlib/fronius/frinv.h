/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# frinv.h
# Fronius inverter class
#
########################################################################*/

#ifndef _FRINV_H
#define _FRINV_H

#include "sockobj.h"
#include "thread.h"

class TFroniusInverter : public TThread
{
public:
    TFroniusInverter(char *IpStr, long IP);
    virtual ~TFroniusInverter();

    bool IsOnline();

    long double GetCurrentPower();
    long double GetDayEnergy();
    long double GetYearEnergy();
    long double GetTotalEnergy();

protected:
    long double GetPowerFact(char *unit);
    long double GetEnergyFact(char *unit);
    void NotifyUnit(char *name, char *unit);
    void NotifyValue(char *name, int index, int value);
    void DecodeUnit(char *name, char *data);
    void DecodeData(char *name, char *data);
    void NotifyField(char *name, char *field, char *data);
    void NotifyParam(char *name, char *data);
    char *GetQuoted(char *str);
    char *GetBlock(char *str);
    virtual void Execute();

    long double FCurrP;
    long double FDayE;
    long double FYearE;
    long double FTotalE;

    long double FCurrFact;
    long double FDayFact;
    long double FYearFact;
    long double FTotalFact;

    bool FOnline;
    long FIP;
    char FIpStr[32];
    TTcpSocket *FSocket;
    char FBuf[2048];

};

#endif

