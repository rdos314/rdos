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
# adc.h
# ADC class
#
########################################################################*/

#ifndef _FREQ_H
#define _FREQ_H

class TFreqData
{
friend class TFreqPos;
public:
    TFreqData(double Freq, double SampleFreq, int Periods);
    ~TFreqData();

    int UsedSamples;
    int Count;
    int Step;

protected:
    int Overlap;
    int Remain;
};

class TFreqPos
{
public:
    TFreqPos();
    ~TFreqPos();

    void Clear(TFreqData *fd);
    void Next(TFreqData *fd);

    int Pos;

protected:
    int Sum;
};

class TFreq
{
public:
    TFreq(double Start, double Stop, int Decimals, double SampleFreq, int Periods);
    ~TFreq();

    void CodeFreq(int index, char *str);
    double GetFreq(int index);

    int Decimals;
    int FreqCount;
    TFreqData **FreqData;

protected:
    double Start;
    double Stop;
    double Step;

    char CodeStr[80];
};


#endif
