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
# convk2.cpp
# Convert exported quiz-k2 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdk2.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000

void OpenPca(const char *Suffix);
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count);
void ClosePca();

static TFile *quizfile;

int GroupArr[121][12] =
{
 {1000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {822, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {845, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {758, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {752, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {739, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 1000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 931, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 866, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 845, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 745, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 923, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, -752, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 799, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 762, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 783, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 765, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 695, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 743, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 610, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 728, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 1000, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 1012, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 894, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 890, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 891, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 911, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 805, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 841, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 828, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 780, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 727, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 741, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 807, 0, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 1000, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, -872, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, -815, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 695, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 679, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, -606, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 632, 0, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 1000, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 1022, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 1011, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 1018, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 923, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 983, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 1049, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 997, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 844, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 879, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 814, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 851, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 901, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 771, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 771, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 803, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 773, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 605, 0, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 1236, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 1238, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 1286, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 1244, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 1172, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 1150, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 1083, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 1100, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 1097, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 1063, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 1000, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 838, 0, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 1000, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 805, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 829, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 836, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 819, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 776, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 804, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 790, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 749, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 662, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 465, 0, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, -1000, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, -838, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, -863, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, -810, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, -665, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, -468, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, -465, 0, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 1000, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 865, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 701, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 639, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 595, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 219, 0, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 1000, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 940, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 931, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 872, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 853, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 945, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 898, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, -746, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 915, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 829, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 766, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 748, 0, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1118, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 943, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1000, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1072, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1122, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1082, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 979, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1024, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1161, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 812, 0},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1000},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1179},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1163},
 {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1185}
};


/*##################  HandleRow ##########################
*   Purpose....: Handle a row                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void HandleRow(TQuizRow *Row)
{
    int grp;

    quizfile->Write(Row, sizeof(TQuizRow));

    printf("K2: %d AS: %d, NT: %d", Row->ID, Row->AsResult, Row->NtResult);

    for (grp = 0; grp < 12; grp++)
        printf(", %d", Row->GroupResult[grp]);
    
    printf("\r\n");
}

/*##################  CalcGroupScores ##########################
*   Purpose....: Calculate group scores                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void CalcGroupScore(TQuizRow *Row)
{
    int grp;
    long long sum;
    long long totsum;
    int i;
    int val;
    int w;
    
    for (grp = 0; grp < 12; grp++)
    {
        sum = 0;
        totsum = 0;

        for (i = 0; i < 121; i++)
        {
            val = Row->Quiz[i];
            if (val)
            {
                w = GroupArr[i][grp];

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
            Row->GroupResult[grp] = 100 * sum / totsum;
        else
            Row->GroupResult[grp] = 0;
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
    int val;
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

            case 15:
                 val = atoi(valstr); // place
                 if (val)
                     Row.HasFlashed = TRUE;
                 else                     
                     Row.HasFlashed = FALSE;
                 Row.Quiz[126] = val;
                 break;

            case 16:
                 if (Row.HasFlashed)
                 {
                     val = atoi(valstr); // my age
                     if (val != 1)
                         val = 2 + (val - 10) / 5;
                 }
                 else
                     val = 0;
                 Row.Quiz[127] = val;
                 break;

            case 17:
                 if (Row.HasFlashed)
                 {
                     val = atoi(valstr); // his age
                     val = 1 + (val - 22) / 5;
                 }
                 else
                     val = 0;

                 Row.Quiz[128] = val;
                 break;

            case 18:
                 if (Row.HasFlashed)
                     Row.Quiz[129] = 1 + atoi(valstr); // girls
                 else
                     Row.Quiz[129] = 0;
                 break;

            case 19:
                 if (Row.HasFlashed)
                     Row.Quiz[130] = 1 + atoi(valstr); // guys
                 else
                     Row.Quiz[130] = 0;
                 break;

            case 20:
                 if (Row.HasFlashed)
                     Row.Quiz[131] = atoi(valstr); // time
                 else
                     Row.Quiz[131] = 0;
                 break;

            case 21:
                 if (Row.HasFlashed)
                     Row.Quiz[132] = 1 + atoi(valstr); // he talk
                 else
                     Row.Quiz[132] = 0;
                 break;

            case 22:
                 if (Row.HasFlashed)
                     Row.Quiz[133] = 1 + atoi(valstr); // you talk
                 else
                     Row.Quiz[133] = 0;
                 break;

            case 23:
                 if (Row.HasFlashed)
                     Row.Quiz[134] = 1 + atoi(valstr); // he approach
                 else
                     Row.Quiz[134] = 0;
                 break;

            case 24:
                 if (Row.HasFlashed)
                     Row.Quiz[135] = 1 + atoi(valstr); // you approach
                 else
                     Row.Quiz[135] = 0;
                 break;

            case 25:
                 if (Row.HasFlashed)
                     Row.Quiz[136] = 1 + atoi(valstr); // notify
                 else
                     Row.Quiz[136] = 0;
                 break;

            case 26:
                 if (Row.HasFlashed)
                     Row.Quiz[137] = 1 + atoi(valstr); // report
                 else
                     Row.Quiz[137] = 0;
                 break;

            case 27:
                 if (Row.HasFlashed)
                     Row.Quiz[138] = atoi(valstr); // scared
                 else
                     Row.Quiz[138] = 0;
                 break;

            case 28:
                 if (Row.HasFlashed)
                     Row.Quiz[139] = atoi(valstr); // disgust
                 else
                     Row.Quiz[139] = 0;
                 break;

            case 29:
                 if (Row.HasFlashed)
                     Row.Quiz[140] = atoi(valstr); // trauma
                 else
                     Row.Quiz[140] = 0;
                 break;

            default:
                 i = fieldno - 30;
                 Row.Quiz[i] = atoi(valstr);
                 break;
        }
    }

    CalcGroupScore(&Row);
    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], 141);
}

/*################## ConvK2 ##########################
*   Purpose....: Convert quiz k2                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvK2()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-k2.csv");
    TFile outfile("bin\\quizk2.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("K2");

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
