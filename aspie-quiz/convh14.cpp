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
# convh14.cpp
# Convert exported quiz-h14 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdh14.h"
#include "convg.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000

void OpenPca(const char *Suffix);
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count);
void ClosePca();

static TFile *quizfile;

static int EyeAlt[28][4] =
  {
    {74, 42, 36, 47},
    {64, 74, 4, 18},
    {53, 74, 42, 29},
    {82, 22, 83, 11},
    {17, 33, 63, 2},
    {85, 74, 66, 60},
    {74, 55, 46, 38},
    {85, 39, 60, 14},
    {38, 74, 9, 36},
    {8, 25, 77, 71},
    {36, 34, 1, 64},
    {74, 17, 81, 67},
    {15, 82, 9, 42},
    {58, 74, 38, 9},
    {74, 44, 68, 8},
    {82, 68, 17, 25},
    {37, 74, 9, 85},
    {74, 34, 16, 48},
    {74, 29, 38, 21},
    {25, 21, 3, 77},
    {38, 74, 77, 36},
    {23, 35, 28, 82},
    {74, 68, 38, 46},
    {25, 67, 17, 74},
    {74, 67, 71, 2},
    {53, 3, 55, 48},
    {43, 25, 71, 33},
    {74, 32, 44, 29}
  };

static int EyeScore[28][4] =
  {
    {63, -30, 27, 0},
    {0, 44, 12, 10},
    {0, 89, 14, 13},
    {26, 0, -20, 4},
    {0, 46, 52, 27},
    {0, 40, 4, -6},
    {47, 0, -2, -17},
    {0, 50, -18, 11},
    {-9, 34, 15, 0},
    {0, 40, 4, -20},
    {43, -3, 0, 18},
    {59, -3, 41, 0},
    {0, 61, 68, -16},
    {0, 62, 5, 34},
    {0, -61, -44, -47},
    {64, 0, 7, 63},
    {0, 69, 38, 29},
    {60, -10, 11, 0},
    {86, -15, 0, 38},
    {45, 0, 1, 8},
    {-39, 60, 0, 12},
    {0, 35, 60, 54},
    {75, 0, 0, 10},
    {38, 0, 5, 40},
    {82, 0, 23, 39},
    {0, 42, 66, 41},
    {-13, 46, 0, 28},
    {94, -2, 0, -6}
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
    quizfile->Write(Row, sizeof(TQuizRow));

//    printf("H14: %d AS: %d, NT: %d, Eye: %d\r\n", Row->ID, Row->AsResult, Row->NtResult, Row->EyeResult);
    printf("%d\n", Row->EyeResult);
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
        int grp;
        int dx;
        int i;
        int val;
        int w;
        int sum;
        int totsum;

        for (grp = 0; grp < 14; grp++)
        {
                sum = 0;
                totsum = 0;

                for (i = 0; i < 145; i++)
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
    int val;
    int minval, maxval;
    int range;
    int count = 0;
    int year, month, day;
    int hour, min, sec;
    TDateTime *time;
    TQuizRow Row;
    int score = 0;

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
                 if (i < 28)
                 {
                    val = atoi(valstr);
                    Row.EyeArr[i] = val;

                    minval = maxval = EyeScore[i][0];
                    
                    for (j = 1; j < 4; j++)
                    {
                        if (EyeScore[i][j] > maxval)
                            maxval = EyeScore[i][j];

                        if (EyeScore[i][j] < minval)
                            minval = EyeScore[i][j];
                    }

                    for (j = 0; j < 4; j++)
                        if (EyeAlt[i][j] == val)
                            break;

                    if (EyeAlt[i][j] == val)
                    {
                        val = EyeScore[i][j];
                        val = val - minval;
                        range = maxval - minval;
                        val = val * 3 / range;
                        if (val == 3)
                            val--;

                        Row.Quiz[150 + i] = val + 1;
                                         
                        score += EyeScore[i][j];
                        count++;
                    }
                    else                                     
                        Row.Quiz[150 + i] = 0;
                 }
                 else
                    i -= 28;                    

                 Row.Quiz[i] = atoi(valstr);
                 break;
        }
    }

    if (count)
    {
        Row.EyeResult = 100 * score / count;

        score = score / count / 9;
        if (score > 3)
            score = 2;
        if (score < 0)
            score = 0;
        score++;
        Row.Quiz[178] = score;

    }
    else
    {
        Row.EyeResult = -1;
        Row.Quiz[178] = 0;
    }

    UpdateScore(&Row);
    HandleRow(&Row);
    AddPca(Row.Gender, Row.BirthYear, Row.AsResult - Row.NtResult, &Row.Quiz[0], 150);
}

/*################## ConvH14 ##########################
*   Purpose....: Convert quiz h14                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvH14()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-h14.csv");
    TFile outfile("bin\\quizh14.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("H14");

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
