/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2020, Leif Ekblad
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
# adcana.h
# ADC analysator class
#
########################################################################*/

#ifndef _ADCANA_H
#define _ADCANA_H

#include "thread.h"
#include "sigdev.h"
#include "adc.h"
#include "adcthr.h"

class TAdcAna : public TThread
{
public:
    TAdcAna();
    ~TAdcAna();

    void Add(TAdcThread *Adc);

    int Total[3500];
    int Count[3500];
    int SumA[3500];
    int SumB[3500];
    int MaxA[3500];
    int MaxB[3500];
    int DelayMean[3500];
    int DelaySd[3500];

protected:
    void Clear();
    virtual void Execute();
};

#endif
