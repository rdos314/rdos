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
# phconv.cpp
# Convert phase to angle
#
########################################################################*/

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define MAX_DIR     10
#define M_PI 3.14159265358979323846

/*##########################################################################
#
#   Name       : CalcDirections
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static int CalcDirections(int DirArr[MAX_DIR], int WaveLen, int Phase, int Distance)
{
    int Pos;
    int Count;
    double Dir;

    Pos = Phase * WaveLen / 360;
    while (Pos - WaveLen > -Distance)
        Pos -= WaveLen;

    Count = 0;

    while (Count < MAX_DIR)
    {
        if (Pos <= -Distance)
            break;
        else
        {
            if (Pos >= Distance)
                break;
            else
            {
                Dir = (double)Pos / (double)Distance;
                Dir = asin(Dir) * 180.0 / M_PI;

                if (Dir >= 0)
                {
                    DirArr[Count] = round(Dir);
                    Count++;

                    if (Count < 16)
                    {
                        DirArr[Count] = 180 - round(Dir);
                        Count++;
                    }
                }
                else
                {
                    DirArr[Count] = 360 + round(Dir);
                    Count++;

                    if (Count < MAX_DIR)
                    {
                        DirArr[Count] = 180 - round(Dir);
                        Count++;
                    }
                }
            }
        }

        if (Pos + WaveLen < Distance)
            Pos += WaveLen;
        else
            break;
    }

    return Count;
}

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
    int phase;
    int dist;
    int vl;
    int freq;
    int count;
    int arr[MAX_DIR];
    int i;

    if (argc == 4)
    {
        dist = atoi(argv[1]);
        freq = atoi(argv[2]);
        phase = atoi(argv[3]);

        printf("dist: %d, freq: %d, phase: %d\r\n", dist, freq, phase);

        vl = 30 * 1000 / freq;
        count = CalcDirections(arr, vl, phase, dist);

        for (i = 0; i < count; i++)
            printf("%d\r\n", arr[i]);
    }
}
