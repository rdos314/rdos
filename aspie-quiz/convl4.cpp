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
# convl4.cpp
# Convert exported quiz-l4 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdl4.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000

int GroupScores[117][10] =
     {
        {861, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {710, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {751, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {689, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {590, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 774, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 728, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 668, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 671, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 631, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 625, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 605, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 691, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 567, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, -620, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 630, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 554, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 582, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 537, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 726, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 620, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 713, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 658, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 770, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 715, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 600, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 707, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 647, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 636, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 576, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 628, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 490, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, -746, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 879, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 537, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, -675, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, -484, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 588, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 534, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 748, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 762, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 733, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 686, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 692, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 709, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 725, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 656, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 681, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 648, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 572, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 590, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 618, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 598, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 500, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 497, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 566, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 802, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 808, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 829, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 719, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 727, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 753, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 776, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 704, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 650, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 661, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 668, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 522, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 525, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 815, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 626, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 637, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 631, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 642, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 608, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 544, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 531, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 424, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 641, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 577, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 552, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 602, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 590, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 420, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 314, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 360, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, -704, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, -760, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 539, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, -421, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, -567, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, -425, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 628, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 713, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 605, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 679, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 706, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 615, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 574, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 682, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 480, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 695},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 776},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 826},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 761},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, -706},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 698},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, -578},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 729},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 700},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 677},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, -634},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 577},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 587},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, -516},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 529},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 544}
     };


void OpenPca(const char *Suffix);
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count);
void ClosePca();

static TFile *quizfile;


/*##################  PrintGroupScore ##########################
*   Purpose....: Print group score                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void PrintGroupScore(TQuizRow *Row)
{
    int grp;
    int w;
    int i;
    int val;
    int sum;
    int totsum;
    int gv[10];
    
    for (grp = 0; grp < 10; grp++)
    {
        sum = 0;
        totsum = 0;

        for (i = 0; i < 117; i++)
        {
            val = Row->Quiz[i];
            if (val)
            {
                w = GroupScores[i][grp];

                if (w < 0)
                {
                    w = -w;
                    val = 3 - val;
                }
                else
                    val--;

                sum += val * w * w;
                totsum += 2 * w * w;
            }        
        }

        if (totsum)
        {
            val = 100 * sum / totsum;
            if (val <= 33)
                val = 0;
            else
            {
                if (val >= 67)
                    val = 2;
                else
                    val = 1;
            }
            gv[grp] = val;
        }
        else
            return;
    }

    for (grp = 0; grp < 10; grp++)
    {
        printf("%d", gv[grp]);
        if (grp == 9)
            printf("\n");
        else
            printf(",");
    }
}

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

    PrintGroupScore(Row);

//    printf("L4: %d AS: %d, NT: %d\r\n", Row->ID, Row->AsResult, Row->NtResult);
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
    int i, j;
    int val;
    int minval, maxval;
    int range;
    int count = 0;
    int year, month, day;
    int hour, min, sec;
    TDateTime *time;
    TQuizRow Row;
    int score = 0;
    int corr_count = 0;

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
                Row.UserID = atol(valstr);
                break;

            case 2:
                sscanf(valstr+1, "%04d-%02d-%02d %02d:%02d:%02d",
                        &year, &month, &day,
                        &hour, &min, &sec);

                time = new TDateTime(year, month, day, hour, min, sec);
                Row.LsbTime = time->GetLsb();
                Row.MsbTime = time->GetMsb();
                delete time;
                break;

            case 3:
                sscanf(valstr+1, "%04d-%02d-%02d %02d:%02d:%02d",
                        &year, &month, &day,
                        &hour, &min, &sec);

                time = new TDateTime(year, month, day, hour, min, sec);
                Row.FilloutTime = time->GetLsb() - Row.LsbTime;
                delete time;
                break;

            case 4:
                Row.BirthYear = atoi(valstr);
                break;

            case 5:
                Row.BirthMonth = atoi(valstr);
                break;

            case 6:
                Row.Gender = atoi(valstr);
                break;

            case 7:
                Row.Country = atoi(valstr);
                break;

            case 8:
                 Row.Ancestry = atoi(valstr);
                 break;

            case 9:
                 Row.Aspie = atoi(valstr);
                 break;

            case 10:
                 Row.ADHD = atoi(valstr);
                 break;

            case 11:
                 Row.OCD = atoi(valstr);
                 break;

            case 12:
                 Row.Social = atoi(valstr);
                 break;

            case 13:
                 Row.AsResult = atoi(valstr);
                 break;

            case 14:
                 Row.NtResult = atoi(valstr);
                 break;

            default:
                 i = fieldno - 15;
                 Row.Quiz[i] = atoi(valstr);
                 break;
        }
    }
        
    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], 121);
}

/*################## ConvL4 ##########################
*   Purpose....: Convert quiz l4                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvL4()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-l4.csv");
    TFile outfile("bin\\quizl4.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("L4");

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
