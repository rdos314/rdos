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
# fuzzy.h
# Fuzzy class
#
########################################################################*/

#ifndef _FUZZY_H
#define _FUZZY_H

#include "fuzzyvar.h"
#include "device.h"

#define MAX_FUZZY_VARS      16 

struct TFuzzyRule
{
    int InputSetArr[MAX_FUZZY_SETS];
    int OutputSet;
};

class TFuzzy : public TDevice
{
public:
    TFuzzy();
    ~TFuzzy();

protected:
    void AddInput(int index, TFuzzyVar *var);
    void AddOutput(TFuzzyVar *var);
    void InitRule();
    void DefineRule(int SetArr[MAX_FUZZY_VARS], int OutputSet);
    long double Calc(long double ValArr[MAX_FUZZY_VARS]);

    TFuzzyVar *FVarArr[MAX_FUZZY_VARS];
    TFuzzyVar *FOutputVar;
    long double *FArr;
    int FSize;
    int FDimCount;
    TFuzzyRule *FRuleArr;
        
};

#endif

