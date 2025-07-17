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
# secsamp.cpp
# Second basis sampling class
#
########################################################################*/

#include "secsamp.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TSecSample::TSecSample
#
#   Purpose....: Constructor for second sampling
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSecSample::TSecSample(int index, const char *unit)
 : TSample(index, unit)
{
    FPrevSec = -1;
    FPrevMin = -1;
    FPrevHour = -1;
    FPrevDay = -1;
    FPrevMonth = -1;
    FPrevYear = -1;
}

/*##########################################################################
#
#   Name       : TSecSample::~TSecSample
#
#   Purpose....: Destructor for second sampling
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSecSample::~TSecSample()
{
}

/*##########################################################################
#
#   Name       : TSecSample::Add
#
#   Purpose....: Add a new sample
#
#   In params..: time       sample time
#                value      sample value
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSecSample::Add(TDateTime *time, long double value)
{
    int ok;

    ok = time->GetYear() == FPrevYear;

    if (ok)
        ok = time->GetMonth() == FPrevMonth;

    if (ok)
        ok = time->GetDay() == FPrevDay;

    if (ok)
        ok = time->GetHour() == FPrevHour;

    if (ok)
        ok = time->GetMin() == FPrevMin;

    if (ok)
        ok = time->GetSec() == FPrevSec;

    if (!ok)
    {
		Clear();
        FPrevYear = time->GetYear();
        FPrevMonth = time->GetMonth();
        FPrevDay = time->GetDay();
        FPrevHour = time->GetHour();
        FPrevMin = time->GetMin();
        FPrevSec = time->GetSec();
    }
    
    TSample::Add(time, value);
}
