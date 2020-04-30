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
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "adc.h"


/*##########################################################################
#
#   Name       : main
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void main()
{
    int i;
    int j;
    int k;
    int PowerA;
    int PowerB;
    TAdcData *data;
    static int PowerSumA[3000];
    static int PowerSumB[3000];

    for (i = 0; i < 3000; i++)
    {
        PowerSumA[i] = 0;
        PowerSumB[i] = 0;
    }

    TAdc Adc(0x0, 5000);

    if (Adc.Start())
    {
        for (i = 0; i < 5000; i++)
        {
            data = Adc.GetBlock(i);

            for (k = 0; k < 16; k++)
            {
                for (j = 300; j < 3000; j++)
                {
                    TAdc::CalcPower(data + 0x8000 * k, 0x8000, j * 0x40000 / 7500 , &PowerA, &PowerB);
                    if (PowerA >= 2 && PowerB >= 2)
                    {
                        PowerSumA[j] += PowerA;
                        PowerSumB[j] += PowerB;
                    }
                }
            }
        }

        for (i = 300; i < 3000; i++)
        {
            if (PowerSumA[i] && PowerSumB[i])
                printf("%d.%01d: %d %d\r\n", i / 10, i % 10, PowerSumA[i], PowerSumB[i]);
        }
    }
}
