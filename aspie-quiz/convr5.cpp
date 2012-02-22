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
# convr5.cpp
# Convert exported quiz-r5 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdbr5.h"
#include "convr5.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000
#define MAX_REFERERS    1024

void OpenPca(const char *Suffix);
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count);
void ClosePca();

static TFile *quizfile;

/*##################  HandleRow ##########################
*   Purpose....: Handle a row                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void HandleRow(TQuizRow *Row)
{
    quizfile->Write(Row, sizeof(TQuizRow));

    printf("R5: %d AS: %d, NT: %d\r\n", Row->ID, Row->AsResult, Row->NtResult);
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
        int dx;
        int w;
    int sum;
    int totsum;

    static int Asw[144] = {
              8,    9,    4,    7,    7,    6,   11,    9,    8,    7,
             14,    8,    7,    5,    8,    5,   11,    4,   11,    8,
             10,   10,    9,   11,    9,   12,   10,   13,   13,    7,
              7,   10,   12,    8,   12,    8,    4,    7,   15,   11,
              7,    5,    7,    5,    3,    7,    4,    3,    5,    5,
              7,    9,   11,   13,    4,    3,    6,    4,    3,   10,
              9,    6,    9,   10,    6,    8,    8,    8,    9,    7,
              7,    6,   13,    9,    4,    9,   13,    9,    7,    9,
              8,    5,    6,    7,    6,    7,    8,    9,    5,    6,
              4,    7,   10,    4,    8,    7,    5,    5,    5,    5,
             11,    7,    5,    9,    7,    4,    4,    4,    6,    4,
              5,    6,    9,    7,    5,    8,    4,    7,    9,    6,
              8,    6,    8,    5,    5,    8,    6,    6,    7,    5,
              9,    6,   10,    8,    7,    5,    4,    5,    6,    5,
              7,    7,    9,    9};

    static int Ntw[144] = {
             -1,   19,   14,    7,   14,   -4,   -5,   -3,   -1,   -3,
              1,   -1,    0,   -5,   -2,    0,   -4,   12,   -3,   -3,
             -3,   -3,    0,   -1,    0,    0,    1,    2,    3,   -3,
             -2,   -6,   -6,   -5,   -4,   -5,   17,    1,    0,   -5,
              3,   13,   13,   13,   16,   -4,    5,   14,   16,   21,
             -6,    0,   -4,    2,   12,   13,   16,   15,   13,   -5,
             -4,   19,   -4,   -2,   -5,   -5,   -5,   -4,   -3,   -4,
             -5,   -5,    2,    0,   13,   -3,    0,   -1,   -2,   -1,
              0,   -5,   -4,    0,   -4,   -2,   -1,    1,    4,   10,
             -5,    1,    2,   -2,   -2,   -4,   -5,   -4,   -5,   -4,
              0,   -1,   -3,    0,   -4,   -2,   -4,   -5,   -1,   -3,
             18,   19,   -8,   -7,   16,   -6,   14,   -7,   -6,   19,
             -3,   15,   -4,   15,   17,   -2,   -7,   12,   -5,   11,
             14,   15,   -1,    0,   15,   -3,   15,   -2,   11,   13,
                          6,    2,    2,   -3};


        for (i = 0; i < 144; i++)
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

        for (i = 0; i < 144; i++)
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
    int j;
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
                                Row.BirthYear = atoi(valstr);
                                break;

                        case 3:
                                Row.BirthMonth = atoi(valstr);
                                break;

                        case 4:
                                Row.Gender = atoi(valstr);
                                break;

                        case 5:
                                Row.Lang = atoi(valstr);
                                break;

                        case 6:
                                Row.Autism = atoi(valstr);
                                break;

                        case 7:
                                Row.Aspie = atoi(valstr);
                                break;

                        case 8:
                                Row.ADHD = atoi(valstr);
                                break;

                        case 9:
                                Row.AsResult = atoi(valstr);
                                break;

                        case 10:
                                Row.NtResult = atoi(valstr);
                                break;

                        default:
                                i = fieldno - 11;
                        Row.Quiz[i] = atoi(valstr);
                                break;
                }
        }

    UpdateScore(&Row);
    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], i + 1);
}

/*################## ConvR5 ##########################
*   Purpose....: Convert quiz R5                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvR5()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-r5.csv");
    TFile outfile("bin\\quizr5.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("R5");

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
