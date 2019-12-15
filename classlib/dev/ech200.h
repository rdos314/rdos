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

    int GetHeatInlet();
    int GetHeatOutlet();
    int GetColdInlet();
    int GetOperTime();
    int GetAutoAlarms();
    int GetManualAlarms();
    bool IsOn();

protected:
    int ReadParam(int index);
    int ReadInput(int index);
    virtual void Execute();

    bool FCooling;
    bool FHeating;
    bool FOn;

    int FHeatInlet;
    int FHeatOutlet;
    int FColdInlet;
    int FOperTime;
    int FAutoAlarms;
    int FManualAlarms;

    TModbus FModbus;

};

#endif

