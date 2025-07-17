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
# yearsamp.cpp
# Year basis sampling class
#
########################################################################*/

#include "yearsamp.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TYearSample::TYearSample
#
#   Purpose....: Constructor for year sampling
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TYearSample::TYearSample(int index, const char *unit)
  : TSample(index, unit)
{
    FPrevYear = -1;
}

/*##########################################################################
#
#   Name       : TYearSample::~TYearSample
#
#   Purpose....: Destructor for year sampling
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TYearSample::~TYearSample()
{
}

/*##########################################################################
#
#   Name       : TYearSample::Add
#
#   Purpose....: Add a new sample
#
#   In params..: time       sample time
#                value      sample value
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TYearSample::Add(TDateTime *time, long double value)
{
    int ok;

    ok = time->GetYear() == FPrevYear;

    if (!ok)
    {
		Clear();
        FPrevYear = time->GetYear();
    }
    
    TSample::Add(time, value);
}
