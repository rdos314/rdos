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
# conv2.cpp
# Convert exported quiz-II to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdb2.h"
#include "conv2.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000

void WritePca(TFile *PcaFile, char *ValArr, int Count);

static TFile quizfile("bin\\quiz2.bin", 0);

/*##################  HandleRow ##########################
 *   Purpose....: Handle a row                                                                   #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-11-20 le                                                #
 *##########################################################################*/
static void HandleRow(TQuizRow *Row)
{
    quizfile.Write(Row, sizeof(TQuizRow));

    printf("II: %d AS: %d, NT: %d\r\n", Row->ID, Row->AsResult, Row->NtResult);
}

/*##################  UpdateScore ##########################
 *   Purpose....: Calculate & update a modified score based on current quiz-weights                                                              #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-11-20 le                                                #
 *##########################################################################*/
static void UpdateScore(TQuizRow *row)
{
    int i;
    int assum = 0;
    int astotsum = 0;
    int ntsum = 0;
    int nttotsum = 0;
    int val;
    int aw;
    int nw;
    int grp;
    int w;
    int sum;
    int totsum;

    static int Asw[100] = {
        13,   10,    9,   10,   13,   14,   14,   15,    9,    6,
        4,    8,    8,    9,    7,   11,   14,    5,    5,   11,
        12,   11,   12,   10,    9,   13,    9,    9,    9,    9,
        13,    5,   12,   10,    5,   10,   11,    7,   14,    9,
        13,    9,   14,    5,    5,   11,    8,   10,   10,   14,
        14,   13,   12,   10,    7,    8,    4,    2,    4,    3,
        13,   14,   15,   13,   15,   13,   14,    9,   12,   12,
        11,    8,   12,    5,    6,   14,    8,    6,   13,    9,
        6,    8,    6,    6,    8,    6,    8,    8,   10,    5,
        12,   14,    7,    7,   13,   10,   10,    7,    4,    7};

    static int Ntw[100] = {
        -5,   -7,   -2,   -2,   -4,   -5,   -6,   -5,   -4,   -6,
        -2,    0,    6,    3,   -1,   -3,   22,   -2,    0,   -6,
        -2,   -5,  -12,  -14,   -7,  -14,   -9,    8,   -8,  -10,
        -10,   -3,   -2,   -4,   -3,   -9,   -3,   20,    8,   -2,
        -9,  -12,   -7,   21,   20,   -5,   11,   29,   -6,   -6,
        -9,    9,   15,   -5,   27,   19,    0,   -2,    0,   -2,
        -2,    0,    7,    1,    5,    2,    4,  -10,   -8,    4,
        -3,  -10,   -5,   17,   15,    7,   26,   17,   -4,    3,
        19,    7,   -4,    0,    3,    6,    0,   -2,   -2,   14,
        3,    3,   20,   16,    0,    3,    6,    6,    1,    0};

    for (i = 0; i < 100; i++)
    {
        if (row->Quiz[i])
        {
            val = row->Quiz[i];
            aw = Asw[i];
            nw = Ntw[i];

            if (aw > 0 && nw > 0)
            {
                if (aw > nw)
                {
                    aw = aw - nw;
                    nw = 0;
                }
                else
                {
                    nw = nw - aw;
                    aw = 0;
                }
            }

            assum += aw * (val - 1);
            astotsum += aw;


            if (nw > 0)
            {
                val--;
                ntsum += nw * val;
                nttotsum += nw;
            }
            else
            {
                val = 3 - val;
                nw = -nw;
                ntsum += nw * val;
                nttotsum += nw;
            }
        }
    }

    row->AsResult = assum * 100 / astotsum;
    row->NtResult = ntsum * 100 / nttotsum;

    for (grp = 0; grp < 14; grp++)
    {
        sum = 0;
        totsum = 0;

        for (i = 0; i < 100; i++)
        {
            val = row->Quiz[i];

            if (val)
            {
                w = Gw[i][grp];

                if (w < 0)
                {
                    w = -w;
                    val = 3 - val;
                }
                else
                    val--;

                sum += val * w;
                totsum += 2 * w;
            }
        }


        if (totsum)
            row->GroupResult[grp] = 100 * sum / totsum;
        else
            row->GroupResult[grp] = 0;
    }
}

/*##################  ProcessRow ##########################
 *   Purpose....: Process row                                                                    #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-11-20 le                                                #
 *##########################################################################*/
static void ProcessRow(char *str)
{
    char *valstr;
    char *ptr;
    int fieldno;
    int i;
    int year, month, day;
    int hour, min, sec;
    TDateTime *time;
    TQuizRow Row;

    ptr = str;
    for (fieldno = 0; ptr; fieldno++)
    {
        valstr = str;
        ptr = strstr(str, ";");
        if (ptr)
            *ptr = 0;

        str = ptr + 1;

        switch (fieldno)
        {
            case 0:
                Row.ID = atol(valstr);
                break;

            case 1:
                sscanf(valstr+1, "%04d-%02d-%02d %02d:%02d:%02d",
                        &year, &month, &day,
                        &hour, &min, &sec);

                time = new TDateTime(year, month, day, hour, min, sec);
                Row.LsbTime = time->GetLsb();
                Row.MsbTime = time->GetMsb();
                delete time;
                break;

            case 2:
                Row.Diagnos = atoi(valstr);
                break;

            case 3:
                Row.BirthYear = atoi(valstr);
                break;

            case 4:
                Row.Gender = atoi(valstr);
                break;

            case 5:
                break;

            default:
                i = fieldno - 6;
                Row.Quiz[i] = atoi(valstr);
                break;

        }                    
    }

    UpdateScore(&Row);
    HandleRow(&Row);
    WritePca(&pcafile, &Row.Quiz[0], i + 1);
}

/*##################  Conv2 ##########################
 *   Purpose....: Conv quiz II                                                           #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-11-20 le                                                #
 *##########################################################################*/
void Conv2()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-II.csv");
    char *ptr;

    OpenPca("2");

    size = infile.Read(buf, MAX_IN_ROW);
    buf[size] = 0;
    ptr = strchr(buf, 0xd);
    if (ptr)
        *ptr = 0;       

    pos += strlen(buf) + 1;
    infile.SetPos(pos);

    while (size = infile.Read(buf, MAX_IN_ROW))
    {
        buf[size] = 0;
        ptr = strchr(buf, 0xd);
        if (ptr)
            *ptr = 0;   

        pos += strlen(buf) + 1;
        infile.SetPos(pos);

        if (ptr)
            ProcessRow(buf);
    }
    ClosePca();


}
