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
# highset.cpp
# High, linear fuzzy set class
#
########################################################################*/

#include "highset.h"

/*##########################################################################
#
#   Name       : THighFuzzySet::THighFuzzySet
#
#   Purpose....: Constructor for high fuzzy set
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THighFuzzySet::THighFuzzySet(long double Low, long double Mid)
{
    FLow = Low;
    FMid = Mid;
	FSlope = 1.0 / (Mid - Low);
}

/*##########################################################################
#
#   Name       : THighFuzzySet::~THighFuzzySet
#
#   Purpose....: Destructor for low fuzzy set
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THighFuzzySet::~THighFuzzySet()
{
}

/*##########################################################################
#
#   Name       : THighFuzzySet::GetValue
#
#   Purpose....: Get value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double THighFuzzySet::GetValue(long double val)
{
    if (val >= FMid)
        return 1.0;
    else
    {
        if (val <= FLow)
            return 0.0;
        else
            return 1.0 - (FMid - val) * FSlope;        
    }
}

/*##########################################################################
#
#   Name       : THighFuzzySet::GetCenter
#
#   Purpose....: Get center
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double THighFuzzySet::GetCenter()
{
    return FMid;
}
