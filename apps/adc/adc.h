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

#ifndef _ADC_H
#define _ADC_H

class TAdcData
{
public:
    short int chA;
    short int chB;
};

class TAdc
{
public:
    TAdc(char TestMode, int Blocks);
    ~TAdc();

    void SetTrigger(int PhaseIncr, int Window);
    bool Start();
    TAdcData *GetBlock(int Block);
    TAdcData *FindStart(int *Entries);

    void Check();

    static int GetSin(int Phase);
    static void CalcPower(TAdcData *Data, int Size, int RelFreq, int *PowerA, int *PowerB);

protected:
    char CheckRamp(TAdcData *data, int Block, int Samples, char Start);
    void CheckRamp();

    int InitPn();
    int UpdatePn(int start);
    int CheckPn(TAdcData *data, int Block, int Samples, int Start);
    void CheckPn();

    int FBlocks;
    char FTestMode;
    char *FBuf;
};

#endif
