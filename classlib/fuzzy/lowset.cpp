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
# lowset.cpp
# Low, linear fuzzy set class
#
########################################################################*/

#include "lowset.h"

/*##########################################################################
#
#   Name       : TLowFuzzySet::TLowFuzzySet
#
#   Purpose....: Constructor for low fuzzy set
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLowFuzzySet::TLowFuzzySet(long double Mid, long double High)
{
    FMid = Mid;
    FHigh = High;
	FSlope = 1.0 / (High - Mid);
}

/*##########################################################################
#
#   Name       : TLowFuzzySet::~TLowFuzzySet
#
#   Purpose....: Destructor for low fuzzy set
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLowFuzzySet::~TLowFuzzySet()
{
}

/*##########################################################################
#
#   Name       : TLowFuzzySet::GetValue
#
#   Purpose....: Get value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TLowFuzzySet::GetValue(long double val)
{
    if (val <= FMid)
        return 1.0;
    else
    {
        if (val >= FHigh)
            return 0.0;
        else
            return 1.0 - (val - FMid) * FSlope;        
    }
}

/*##########################################################################
#
#   Name       : TLowFuzzySet::GetCenter
#
#   Purpose....: Get center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TLowFuzzySet::GetCenter()
{
    return FMid;
}
