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
# fuzzy.cpp
# Fuzzy class
#
########################################################################*/

#include <math.h>
#include "fuzzy.h"

#define FALSE   0
#define TRUE    !FALSE

#ifdef __WATCOMC__
#define sqrtl sqrt
#endif

/*##########################################################################
#
#   Name       : TFuzzy::TFuzzy
#
#   Purpose....: Constructor for fuzzy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFuzzy::TFuzzy()
{
    int i;

    for (i = 0; i < MAX_FUZZY_VARS; i++)
                FVarArr[i] = 0;
                
    FOutputVar = 0;
    FSize = 1;
    FArr = 0;
    FRuleArr = 0;
}

/*##########################################################################
#
#   Name       : TFuzzy::~TFuzzy
#
#   Purpose....: Destructor for fuzzy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFuzzy::~TFuzzy()
{
    int i;

    for (i = 0; i < MAX_FUZZY_VARS; i++)
        if (FVarArr[i])
            delete FVarArr[i];

    if (FOutputVar)
        delete FOutputVar;

    if (FArr)
        delete FArr;

    if (FRuleArr)
        delete FRuleArr;
}

/*##########################################################################
#
#   Name       : TFuzzy::AddInput
#
#   Purpose....: Add input var
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFuzzy::AddInput(int index, TFuzzyVar *var)
{
    if (index < 0 || index >= MAX_FUZZY_VARS)
        delete var;
    else
    {
        if (FVarArr[index])
            delete FVarArr[index];

        FVarArr[index] = var;
    }
}

/*##########################################################################
#
#   Name       : TFuzzy::AddOutput
#
#   Purpose....: Add output var
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFuzzy::AddOutput(TFuzzyVar *var)
{
    if (FOutputVar)
        delete FOutputVar;

    FOutputVar = var;
}

/*##########################################################################
#
#   Name       : TFuzzy::InitRule
#
#   Purpose....: Init rules
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFuzzy::InitRule()
{
    int i;
    int j;
    int Arr[MAX_FUZZY_SETS];

    FDimCount = 0;
    FSize = 1;
    for (i = 0; i < MAX_FUZZY_VARS; i++)
    {
        if (FVarArr[i])
        {
            FSize = FSize * FVarArr[i]->GetSets();
            FDimCount++;
        }
    }

    if (FArr)
        delete FArr;

    FArr = new long double[FSize];

    if (FRuleArr)
        delete FRuleArr;
        
    FRuleArr = new TFuzzyRule[FSize];

    for (i = 0; i < MAX_FUZZY_SETS; i++)
        Arr[i] = 0;

    for (i = 0; i < FSize; i++)
        {
                FRuleArr[i].OutputSet = 0;

                for (j = 0; j < MAX_FUZZY_SETS; j++)
                        FRuleArr[i].InputSetArr[j] = Arr[j];

                for (j = 0; j < MAX_FUZZY_SETS; j++)
                {
                        if (FVarArr[j])
                        {
                                Arr[j]++;

                if (Arr[j] >= FVarArr[j]->GetSets())
                    Arr[j] = 0;
                else
                    break;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TFuzzy::DefineRule
#
#   Purpose....: Define rule
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFuzzy::DefineRule(int SetArr[MAX_FUZZY_VARS], int OutputSet)
{
    int i;
    int j;
    int ok;

    if (!FArr)
        InitRule();

    ok = FALSE;

    for (i = 0; i < FSize && !ok; i++)
        {
                ok = TRUE;

                for (j = 0; j < MAX_FUZZY_VARS && ok; j++)
                        if (FVarArr[j])
                                if (FRuleArr[i].InputSetArr[j] != SetArr[j])
                                        ok = FALSE;

                if (ok)
                        FRuleArr[i].OutputSet = OutputSet;
    }
}
    
/*##########################################################################
#
#   Name       : TFuzzy::Calc
#
#   Purpose....: Calc output value from inputs
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TFuzzy::Calc(long double ValArr[MAX_FUZZY_VARS])
{
    int i;
    int j;
    int set;
    long double val;
    long double minval;
    long double prodsum;
    long double sum;
    long double OutputSum[MAX_FUZZY_VARS * MAX_FUZZY_SETS];

    for (i = 0; i < MAX_FUZZY_VARS; i++)
        if (FVarArr[i])
                        FVarArr[i]->SetInputValue(ValArr[i]);

    for (i = 0; i < MAX_FUZZY_VARS * MAX_FUZZY_SETS; i++)
        OutputSum[i] = 0.0;
    
    for (i = 0; i < FSize; i++)
    {
        minval = 1.0;
    
        for (j = 0; j < MAX_FUZZY_VARS && minval != 0.0; j++)
        {
            if (FVarArr[j])
            {
                set = FRuleArr[i].InputSetArr[j];            
                val = FVarArr[j]->GetValue(set);
                if (val < minval)
                    minval = val;
            }
        }

        set = FRuleArr[i].OutputSet;
        OutputSum[set] += minval * minval;
    }

    prodsum = 0.0;
    sum = 0.0;
    
    for (i = 0; i < MAX_FUZZY_VARS * MAX_FUZZY_SETS; i++)
    {
        if (OutputSum[i] != 0.0)
        {
            OutputSum[i] = sqrtl(OutputSum[i]);
            prodsum += OutputSum[i] * FOutputVar->GetCenter(i);
            sum += OutputSum[i];            
        }
    }

    if (sum)
        return prodsum / sum;
    else
        return 0.0;
}
