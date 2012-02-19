/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# conv.cpp
# Convert exported quiz to binary files
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"

void Conv1();
void Conv2();
void Conv3();
void ConvNd();
void Conv5();
void Conv6();
void Conv7();
void Conv8();
void Conv9();
void ConvR1();
void ConvR2();

/*##################  WritePca ##########################
*   Purpose....: Write PCA                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WritePca(TFile *PcaFile, char *ValArr, int Count)
{
    int i;
    int val;
    char str[12];
    
    for (i = 0; i < Count; i++)
    {
        val = ValArr[i];
        if (val > 0)
            val--;

        if (i == Count - 1)            
            sprintf(str, "%d\r\n", val);
        else
            sprintf(str, "%d,", val);

        PcaFile->Write(str);
    }    
}

/*##################  main ##########################
*   Purpose....: Program entry-point                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
    Conv1();
    Conv2();
    Conv3();
    ConvNd();
    Conv5();
    Conv6();
    Conv7();
    Conv8();
    Conv9();
    ConvR1();
    ConvR2();

    return 0;
}
