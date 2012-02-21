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
# convnd.cpp
# Convert exported quiz-ND to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdbnd.h"
#include "convnd.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000

void OpenPca(const char *Suffix);
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count);
void ClosePca();

TFile *quizfile;

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

    printf("ND: %d AS: %d, NT: %d\r\n", Row->ID, Row->AsResult, Row->NtResult);
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

    static int Asw[210] = {
             11,    9,   14,    9,   11,    7,    8,   11,    8,    3,
             12,    6,    8,    8,    9,    6,   10,    3,    6,    6,
              6,    7,    5,    4,    7,    7,    3,    6,   11,    7,
              9,    9,   12,    8,    9,    6,    3,   10,    9,    7,
              6,   10,    9,    7,    8,    4,    3,    7,    5,    7,
              8,    8,    4,    5,    2,    3,    6,    5,   12,   12,
              6,   11,    5,    5,   13,   13,   10,   12,    8,    7,
             12,    7,    8,    5,    5,    6,    4,    9,    5,    7,
              5,    8,    8,    9,   10,    5,    9,    7,    8,    4,
              7,    5,    6,   13,    3,    4,    5,   12,   10,   15,
              6,   12,   11,    5,    9,    6,   11,    4,   12,    4,
             10,    5,    7,   12,    3,    8,    7,    7,    2,    9,
              7,    7,    3,    7,    6,    3,   11,   13,    3,    3,
              4,    8,    6,    7,    3,    6,    5,    6,    8,    7,
              9,    5,    4,    7,    6,    6,   10,    8,   10,   10,
              8,    4,    9,    8,    8,    8,    3,   13,    7,    4,
              4,    5,    7,    3,    4,    6,    7,   12,    3,    3,
              5,    4,    5,    9,    8,    9,    8,    8,    6,    8,
             11,    4,    9,    0,    5,    6,    3,    1,   11,   10,
              6,    6,    6,    9,    8,    9,    4,    5,    7,    3,
              1,    1,    1,    1,    2,    0,    1,    1,    0,    1};

    static int Ntw[210] = {
              1,   -7,    3,   -1,    0,   -2,    1,   -3,   -2,   -2,
             -7,   -7,   -3,   -5,   -3,    0,   -2,   -5,   -7,   10,
             -6,    9,   10,    7,    6,    3,   -4,   -6,  -11,   15,
            -10,  -11,   -7,  -10,    7,   -1,   10,   -3,   -7,   14,
            -10,   14,   -3,   -5,   -7,    7,   -4,   15,   12,   -7,
             -4,   -1,   -4,   -3,   -1,   -3,    0,   -5,    0,   -3,
             11,   -5,   10,    8,    0,    1,   -3,    5,   -2,    8,
                         -2,   -4,    0,   12,   12,    7,    8,   -6,   -6,    6,
              8,   10,   -9,   -6,   -4,   11,   -3,    0,   -2,   -2,
             -3,   14,   14,   -4,    6,   12,   -5,   -7,   -4,    4,
              6,   -3,    0,   16,   22,   13,   -1,    3,   -4,   10,
             11,    8,   -8,   -4,    0,    6,    9,    2,    2,    0,
             19,   -4,    9,   -8,   14,    9,   -8,   -7,    9,   11,
             -1,   16,   14,   11,    9,   12,    6,   12,    5,    1,
              0,   -1,    4,    0,    8,    6,    0,   -1,    0,   -6,
              0,   10,    1,   -1,   -1,   -1,   -3,    8,    4,   -2,
             -2,   -1,   -2,   -1,   -1,   -5,    6,    6,    0,    0,
              0,   -1,   -3,   -3,    5,   -4,   -7,   -5,    7,   -2,
             -9,    0,   -3,    0,   -3,    0,    0,    0,    1,    0,
              6,    0,    0,    8,    8,   -7,    8,    9,    1,    5,
             -1,    0,    0,    0,   -1,    0,    0,   -1,    0,   -1};


        for (i = 0; i < 200; i++)
        {
                if (row->Quiz[i] < 0 || row->Quiz[i] > 3)
                exit;

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

        if (row->AsResult < 0 || row->AsResult >= 200)
                exit;

        if (row->NtResult < 0 || row->NtResult >= 200)
                exit;

    for (grp = 0; grp < 14; grp++)
    {
                sum = 0;
        totsum = 0;

        for (i = 0; i < 200; i++)
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
                                Row.BirthYear = atoi(valstr);
                                break;

                        case 3:
                                Row.Gender = atoi(valstr);
                                break;

                        case 4:
                                Row.Autism = atoi(valstr);
                                break;

                        case 5:
                                Row.Aspie = atoi(valstr);
                                break;

                        case 6:
                                Row.ADHD = atoi(valstr);
                                break;

                        case 7:
                                Row.TS = atoi(valstr);
                                break;

                        case 8:
                                Row.Hyperlexia = atoi(valstr);
                                break;

                        case 9:
                                Row.Dyspraxia = atoi(valstr);
                                break;

                        case 10:
                                Row.Dyslexia = atoi(valstr);
                                break;

                        case 11:
                                Row.Dyscalculia = atoi(valstr);
                                break;

                        case 12:
                                Row.OCD = atoi(valstr);
                                break;

                        case 13:
                                Row.ODD = atoi(valstr);
                                break;

                        case 14:
                                Row.Synaesthesia = atoi(valstr);
                                break;

                        case 15:
                                Row.PA = atoi(valstr);
                                break;

                        case 16:
                                Row.Dysgraphia = atoi(valstr);
                                break;

                        case 17:
                                Row.Bipolar = atoi(valstr);
                                break;

                        case 18:
                                Row.AsResult = atoi(valstr);
                                break;

                        case 19:
                                Row.NtResult = atoi(valstr);
                                break;

                        default:
                                i = fieldno - 20;
                                Row.Quiz[i] = atoi(valstr);
                                break;

        }                    
    }

    UpdateScore(&Row);
    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], i + 1);
}

/*################## ConvNd ##########################
*   Purpose....: Conv quiz ND                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvNd()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-nd.csv");
    TFile outfile("bin\\quiznd.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("nd");

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

