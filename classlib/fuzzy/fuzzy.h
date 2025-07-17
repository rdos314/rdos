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

