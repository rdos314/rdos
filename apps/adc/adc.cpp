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
# adc.cpp
# ADC class
#
########################################################################*/

#include <rdos.h>
#include "adc.h"

/*##########################################################################
#
#   Name       : TAdc::TAdc
#
#   Purpose....: Constructor for Adc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdc::TAdc(char TestMode, int Blocks)
{
    FTestMode = TestMode;
    FBlocks = Blocks;
    FBuf = (char *)RdosAllocateMem(0x200000);

    RdosSetupAdc(TestMode, 0, FBlocks);
}

/*##########################################################################
#
#   Name       : TAdc::~TAdc
#
#   Purpose....: Destructor for Adc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdc::~TAdc()
{
    RdosFreeMem(FBuf);
}

/*##########################################################################
#
#   Name       : TAdc::Start
#
#   Purpose....: start ADC
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAdc::Start()
{
    char state = RdosStartAdc();

    if (state & 0x20)
         return true;
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAdc::GetBlock
#
#   Purpose....: Get ADC block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdcData *TAdc::GetBlock(int Block)
{
    bool ok;

    ok = RdosMapAdcBlock(Block, FBuf);
    if (ok)
        return (TAdcData *)FBuf;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TAdc::FindStart
#
#   Purpose....: Find start of ADC data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAdcData *TAdc::FindStart(int *Entries)
{
    int i;
    TAdcData *data = GetBlock(0);

    if (data)
    {
        *Entries = 0x80000;

        switch (FTestMode)
        {
            case 0:
                *Entries -= 0x20;
                return data + 0x20;           

            case 0xF:
                for (i = 0; i < 0x20; i++)
                {
                    if (data->chA == 0 && data->chB == 0)
                        break;
                    else
                    {
                        data++;
                        (*Entries)--;
                    }
                }
                return 0;

           default:
               return 0;
        }
    }                    
    return 0;
}

