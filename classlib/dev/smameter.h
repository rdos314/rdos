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
# smameter.h
# SMA energy meter
#
########################################################################*/

#ifndef _SMAMETER_H
#define _SMAMETER_H

#include "thread.h"
#include "rdos.h"
#include "section.h"

class TSmaMeter : public TThread
{
public:
    TSmaMeter();
    virtual ~TSmaMeter();

    double GetVolt(int Phase);
    double GetCurrent(int Phase);
    double GetConsumePower();
    double GetConsumePower(int Phase);
    double GetProducePower();
    double GetProducePower(int Phase);
    double GetConsumeEnergy();
    double GetConsumeEnergy(int Phase);
    double GetProduceEnergy();
    double GetProduceEnergy(int Phase);

protected:
    virtual void Execute();

    double FVolt[3];
    double FCurrent[3];
    double FConsumePower[4];
    double FProducePower[4];
    double FConsumeEnergy[4];
    double FProduceEnergy[4];
    TSection FSection;
};

#endif

