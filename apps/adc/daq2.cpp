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
#include <math.h>
#include "file.h"
#include "datetime.h"
#include "freq.h"
#include "adcthr.h"
#include "adcana.h"
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
int main(int argc, char **argv)
{
    char str[80];
    int *parm;
    int hour;
    TDateTime curr;

    double SampleFreq = 600.0;
    TFreq Freq(0.1, SampleFreq / 2.0, 1, SampleFreq, 250);

    TAdc Adc(0x0, 30000, &Freq);

    if (argc == 2)
    {
        hour = atoi(argv[1]);
        sprintf(str, "Wait until %d:00", hour);
        RdosWriteString(str);

        TDateTime starttime(curr.GetYear(), curr.GetMonth(), curr.GetDay(), hour, 0, 0);

        while (!starttime.HasExpired())
            RdosWaitMilli(1000);
    }

    Adc.RunAdc(300, 22, 100, "res.txt");

    for (;;)
        RdosWaitMilli(100);
}
