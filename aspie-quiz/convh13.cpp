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
# convh13.cpp
# Convert exported quiz-h13 to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdh13.h"
#include "convg.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x8000

void OpenPca(const char *Suffix);
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count);
void ClosePca();

static TFile *quizfile;

static int EyeAlt[28][6] =
  {
    {44, 74, 42, 23, 36, 47},
    {64, 36, 74, 4, 66, 18},
    {29, 53, 74, 11, 81, 42},
    {83, 22, 85, 16, 82, 79},
    {17, 25, 2, 11, 33, 63},
    {85, 60, 66, 74, 77, 22},
    {38, 74, 46, 72, 1, 55},
    {60, 85, 75, 39, 14, 80},
    {36, 38, 70, 79, 9, 74},
    {71, 8, 77, 43, 25, 58},
    {34, 43, 37, 36, 1, 64},
    {67, 74, 38, 17, 11, 81},
    {42, 82, 60, 28, 9, 15},
    {58, 74, 82, 38, 79, 9},
    {74, 29, 8, 68, 48, 44},
    {17, 38, 25, 36, 82, 68},
    {85, 74, 37, 9, 28, 67},
    {74, 34, 48, 76, 38, 16},
    {38, 29, 21, 74, 36, 70},
    {21, 74, 77, 3, 25, 67},
    {38, 77, 74, 67, 36, 2},
    {23, 82, 6, 28, 59, 35},
    {74, 46, 80, 68, 67, 38},
    {67, 19, 25, 17, 74, 40},
    {85, 71, 55, 67, 2, 74},
    {48, 53, 74, 55, 3, 36},
    {71, 40, 25, 43, 33, 20},
    {32, 74, 44, 65, 29, 53}
  };

static int EyeScore[28][6] =
  {
    {3, 50, 0, 4, 34, 0},
    {-15, 0, 34, -2, 19, 18},
    {20, 0, 56, 17, 54, 30},
    {0, 0, 1, 17, 41, 16},
    {0, 15, 33, 20, 39, 54},
    {0, 15, 21, 42, 21, 10},
    {-15, 35, -25, -13, -17, 0},
    {21, 0, 9, 54, 0, 18},
    {0, -33, -11, 6, 5, 21},
    {0, -20, 3, 3, 37, -4},
    {-3, 2, 21, 42, 0, 24},
    {-30, 0, -49, -45, -50, 19},
    {-5, 33, 4, 32, 32, 0},
    {0, 56, 37, 14, 31, 36},
    {0, -33, 1, -20, -15, -40},
    {5, 11, 46, 26, 52, 0},
    {15, 57, 0, 32, 35, 24},
    {48, -4, 0, 1, -4, 32},
    {0, -7, 32, 67, 15, 16},
    {0, 26, 8, 5, 47, -1},
    {-33, 0, 19, -12, 0, 2},
    {0, 36, 34, 29, 29, 43},
    {52, 5, 22, 0, 12, -1},
    {0, 22, 54, 8, 33, 22},
    {5, 0, 13, -11, 33, 55},
    {7, 0, 38, 33, 41, 35},
    {0, 0, 38, -12, 18, 13},
    {-10, 60, 0, 1, 11, 21}
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

//    printf("H13: %d AS: %d, NT: %d, Eye: %d\r\n", Row->ID, Row->AsResult, Row->NtResult, Row->EyeResult);
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
                    
                    for (j = 1; j < 6; j++)
                    {
                        if (EyeScore[i][j] > maxval)
                            maxval = EyeScore[i][j];

                        if (EyeScore[i][j] < minval)
                            minval = EyeScore[i][j];
                    }

                    for (j = 0; j < 6; j++)
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

/*################## ConvH13 ##########################
*   Purpose....: Convert quiz h13                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ConvH13()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz-h13.csv");
    TFile outfile("bin\\quizh13.bin", 0);
    char *ptr;

    quizfile = &outfile;
    OpenPca("H13");

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
